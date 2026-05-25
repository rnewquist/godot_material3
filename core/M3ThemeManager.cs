using Godot;
using System;

namespace Material3.Core;

/// <summary>
/// A global singleton coordinator (Autoload) managing active Material 3 themes,
/// seed color generations, and light/dark toggles.
/// </summary>
public partial class M3ThemeManager : Node
{
    private static M3ThemeManager _instance;

    /// <summary>
    /// Static singleton instance accessor.
    /// </summary>
    public static M3ThemeManager Instance => _instance;

    private M3Theme _currentTheme;
    private bool _isDarkMode = false;
    private Color _currentSeedColor = Color.FromHtml("#6750A4");
    private float _scaleFactor = -1.0f; // Uninitialized indicator for dynamic scale
    private bool _isManualScaleOverride = false;

    /// <summary>
    /// Event fired when the theme changes (colors modified, dark mode toggled, seed updated, or scale factor modified).
    /// </summary>
    public event Action ThemeChanged;

    /// <summary>
    /// The currently active Material 3 theme containing colors and shape tokens.
    /// </summary>
    public M3Theme CurrentTheme
    {
        get => _currentTheme;
        private set
        {
            _currentTheme = value;
            ThemeChanged?.Invoke();
        }
    }

    /// <summary>
    /// Gets or sets the global visual scale factor (DPI scaling multiplier).
    /// </summary>
    public float ScaleFactor
    {
        get
        {
            if (_scaleFactor < 0.0f)
            {
                RecalculateDynamicScaleFactor();
            }
            return _scaleFactor;
        }
        set
        {
            _isManualScaleOverride = true;
            if (_scaleFactor != value)
            {
                _scaleFactor = value;
                ThemeChanged?.Invoke();
            }
        }
    }

    /// <summary>
    /// Resets manual scale factor override, enabling dynamic scaling calculations on window resizes.
    /// </summary>
    public void ClearScaleOverride()
    {
        _isManualScaleOverride = false;
        _scaleFactor = -1.0f; // Force recalculation
        RecalculateDynamicScaleFactor();
    }

    public override void _Ready()
    {
        RecalculateDynamicScaleFactor();
        var viewport = GetViewport();
        if (viewport != null)
        {
            viewport.SizeChanged += RecalculateDynamicScaleFactor;
        }
    }

    /// <summary>
    /// Computes the Density-Independent Pixel (DP) scaling factor dynamically
    /// based on physical screen DPI and viewport dimensions.
    /// </summary>
    public void RecalculateDynamicScaleFactor()
    {
        if (_isManualScaleOverride) return;

        // 1. DPI-based density scale (standardized against a 96 DPI baseline)
        float dpiScale = 1.0f;
        try
        {
            float dpi = DisplayServer.ScreenGetDpi();
            if (dpi > 0)
            {
                dpiScale = dpi / 96.0f;
            }
        }
        catch (Exception)
        {
            // Fail-safe fallback if DisplayServer is unavailable in early init or headless mode
        }

        // Combine hardware density and screen real-estate scaling
        float dynamicScale = dpiScale;
        
        // Clamp final scale factor between 1.0x and 3.0x to maintain readability and prevent clipping
        float newScale = Mathf.Clamp(dynamicScale, 1.0f, 3.0f);
        
        if (_scaleFactor != newScale)
        {
            _scaleFactor = newScale;
            ThemeChanged?.Invoke();
        }
    }

    /// <summary>
    /// Gets or sets whether dark mode is currently active.
    /// </summary>
    public bool IsDarkMode
    {
        get => _isDarkMode;
        set
        {
            if (_isDarkMode != value)
            {
                _isDarkMode = value;
                RegenerateTheme();
            }
        }
    }

    /// <summary>
    /// Gets or sets the primary seed color from which the palette is derived.
    /// </summary>
    public Color CurrentSeedColor
    {
        get => _currentSeedColor;
        set
        {
            if (_currentSeedColor != value)
            {
                _currentSeedColor = value;
                RegenerateTheme();
            }
        }
    }

    public override void _EnterTree()
    {
        if (_instance == null)
        {
            _instance = this;
        }

        // Initialize default theme
        _currentTheme = new M3Theme();
        RegenerateTheme();
    }

    /// <summary>
    /// Forces the reconstruction of the tonal palette using the current seed color and dark mode state.
    /// </summary>
    public void RegenerateTheme()
    {
        var newTheme = new M3Theme();
        newTheme.GenerateFromSeed(_currentSeedColor, _isDarkMode);
        CurrentTheme = newTheme;
    }
}
