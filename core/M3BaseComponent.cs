using Godot;
using System;
using Material3.Effects;

namespace Material3.Core;

/// <summary>
/// Abstract base Control class for all Material 3 components.
/// Automates state listener hooks, dynamic themes, and ripple drawing.
/// </summary>
public abstract partial class M3BaseComponent : Control
{
    private bool _isHovered = false;
    private bool _isFocused = false;
    private bool _isPressed = false;

    protected M3Ripple RippleNode { get; private set; }

    /// <summary>
    /// Convenient accessor to the global theme manager singleton.
    /// </summary>
    public M3Theme CurrentTheme
    {
        get
        {
            if (M3ThemeManager.Instance == null)
            {
                return new M3Theme(); // Fail-safe default theme fallback
            }
            return M3ThemeManager.Instance.CurrentTheme;
        }
    }

    /// <summary>
    /// Gets the current global visual scale factor (DPI multiplier).
    /// </summary>
    public float ScaleFactor => M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

    public override void _EnterTree()
    {
        // Subscribe to global theme updates
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged += OnThemeChanged;
        }
    }

    public override void _ExitTree()
    {
        // Clean up events to prevent memory leaks
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged -= OnThemeChanged;
        }
    }

    public override void _Ready()
    {
        // Add dynamic M3 Ripple layer as first child
        RippleNode = new M3Ripple();
        AddChild(RippleNode);

        // Bind standard input hooks for states
        MouseEntered += () => { _isHovered = true; QueueRedraw(); };
        MouseExited += () => { _isHovered = false; _isPressed = false; QueueRedraw(); };
        FocusEntered += () => { _isFocused = true; QueueRedraw(); };
        FocusExited += () => { _isFocused = false; QueueRedraw(); };

        ApplyTheme();
    }

    public override void _GuiInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (mouseEvent.Pressed)
            {
                _isPressed = true;
                RippleNode.TriggerRipple(mouseEvent.Position);
                QueueRedraw();
            }
            else
            {
                _isPressed = false;
                QueueRedraw();
            }
        }
    }

    /// <summary>
    /// Virtual method called whenever a global theme event propagates.
    /// Derived controls must override this to rebind their styleboxes and colors.
    /// </summary>
    protected virtual void ApplyTheme()
    {
        QueueRedraw();
    }

    private void OnThemeChanged()
    {
        ApplyTheme();
    }

    // --- State Helper Accessors ---

    protected bool IsHoveredState() => _isHovered && !IsDisabled();
    protected bool IsFocusedState() => _isFocused && !IsDisabled();
    protected bool IsPressedState() => _isPressed && !IsDisabled();
    protected bool IsDisabled() => FocusMode == FocusModeEnum.None;
}
