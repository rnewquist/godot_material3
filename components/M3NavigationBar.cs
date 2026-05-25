using Godot;
using System;
using System.Collections.Generic;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Navigation Bar (Bottom Navigation).
/// Sits at the bottom, holding 3-5 items with capsule active indicators.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3NavigationBar : Control
{
    private HBoxContainer _hbox;
    private int _selectedIndex = 0;
    private readonly List<string> _items = new() { "Home", "Search", "Settings" };
    private readonly List<Texture2D> _icons = new();
    private readonly List<M3NavigationItem> _childItems = new();

    [Signal]
    public delegate void ItemSelectedEventHandler(int index);

    [Export]
    public int SelectedIndex
    {
        get => _selectedIndex;
        set
        {
            if (value >= 0 && value < _childItems.Count && _selectedIndex != value)
            {
                _selectedIndex = value;
                UpdateSelection();
                EmitSignal(SignalName.ItemSelected, _selectedIndex);
            }
        }
    }

    private M3Theme CurrentTheme
    {
        get
        {
            if (M3ThemeManager.Instance == null)
            {
                return new M3Theme();
            }
            return M3ThemeManager.Instance.CurrentTheme;
        }
    }

    public override void _Ready()
    {
        _hbox = new HBoxContainer();
        _hbox.SetAnchorsPreset(LayoutPreset.FullRect);
        _hbox.Alignment = BoxContainer.AlignmentMode.Center;
        _hbox.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        _hbox.SizeFlagsVertical = SizeFlags.ExpandFill;
        AddChild(_hbox);

        ApplyTheme();
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged += ApplyTheme;
        }
    }

    public override void _ExitTree()
    {
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged -= ApplyTheme;
        }
    }

    private void ApplyTheme()
    {
        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;
        CustomMinimumSize = new Vector2(200, 80) * scaleFactor; // M3 spec height is 80dp scaled
        RebuildNavBar();
        QueueRedraw();
    }

    /// <summary>
    /// Re-constructs the bottom items from layout configs.
    /// </summary>
    private void RebuildNavBar()
    {
        if (_hbox == null) return;

        // Clear existing
        foreach (var child in _childItems)
        {
            child.QueueFree();
        }
        _childItems.Clear();

        // Add child items
        for (int i = 0; i < _items.Count; i++)
        {
            int currentIndex = i;
            var itemNode = new M3NavigationItem(i, _items[i], i < _icons.Count ? _icons[i] : null);
            itemNode.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            itemNode.SizeFlagsVertical = SizeFlags.ExpandFill;
            itemNode.Pressed += () => SelectedIndex = currentIndex;
            _hbox.AddChild(itemNode);
            _childItems.Add(itemNode);
        }

        UpdateSelection();
    }

    private void UpdateSelection()
    {
        for (int i = 0; i < _childItems.Count; i++)
        {
            _childItems[i].SetActive(i == _selectedIndex);
        }
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        // Draw standard M3 bottom bar panel background
        StyleBoxFlat barPanel = new StyleBoxFlat();
        barPanel.BgColor = CurrentTheme.SurfaceVariant;
        barPanel.BorderWidthTop = (int)(1 * scaleFactor);
        barPanel.BorderColor = CurrentTheme.OutlineVariant;

        DrawStyleBox(barPanel, new Rect2(Vector2.Zero, Size));
    }
}

/// <summary>
/// Sub-component representing a single tab item in the bottom navbar.
/// </summary>
internal partial class M3NavigationItem : Control
{
    private readonly int _index;
    private readonly string _labelTxt;
    private readonly Texture2D _iconTexture;

    private VBoxContainer _vbox;
    private Control _capsuleFrame;
    private TextureRect _iconRect;
    private Label _label;

    private float _activePercent = 0.0f; // Tween factor driven on select transitions

    public event Action Pressed;

    private M3Theme CurrentTheme
    {
        get
        {
            if (M3ThemeManager.Instance == null)
            {
                return new M3Theme();
            }
            return M3ThemeManager.Instance.CurrentTheme;
        }
    }

    public M3NavigationItem(int index, string label, Texture2D icon)
    {
        _index = index;
        _labelTxt = label;
        _iconTexture = icon;
        FocusMode = FocusModeEnum.Click;
    }

    public override void _Ready()
    {
        _vbox = new VBoxContainer();
        _vbox.Alignment = BoxContainer.AlignmentMode.Center;
        _vbox.SetAnchorsPreset(LayoutPreset.FullRect);
        AddChild(_vbox);

        // Center capsule wrapper for icon
        _capsuleFrame = new Control();
        _capsuleFrame.SizeFlagsHorizontal = SizeFlags.ShrinkCenter;
        _vbox.AddChild(_capsuleFrame);

        _iconRect = new TextureRect();
        _iconRect.ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize;
        _iconRect.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
        _iconRect.SetAnchorsPreset(LayoutPreset.Center);
        _iconRect.MouseFilter = MouseFilterEnum.Ignore;
        _capsuleFrame.AddChild(_iconRect);

        _label = new Label();
        _label.Text = _labelTxt;
        _label.HorizontalAlignment = HorizontalAlignment.Center;
        _label.MouseFilter = MouseFilterEnum.Ignore;
        _vbox.AddChild(_label);

        ApplyItemStyle();
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged += ApplyItemStyle;
        }
    }

    public override void _ExitTree()
    {
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged -= ApplyItemStyle;
        }
    }

    public void SetActive(bool isActive)
    {
        float target = isActive ? 1.0f : 0.0f;
        var tween = CreateTween();
        
        // M3 item select transition is extremely swift (100ms - 150ms)
        tween.TweenProperty(this, "_activePercent", target, 0.125f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);
        
        tween.Finished += ApplyItemStyle;
    }

    public override void _GuiInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (!mouseEvent.Pressed)
            {
                Pressed?.Invoke();
            }
        }
    }

    private void ApplyItemStyle()
    {
        if (CurrentTheme == null || _label == null || _iconRect == null || _capsuleFrame == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        _capsuleFrame.CustomMinimumSize = new Vector2(64, 32) * scaleFactor; // M3 capsule dimensions scaled
        _iconRect.CustomMinimumSize = new Vector2(24, 24) * scaleFactor;
        
        _vbox.AddThemeConstantOverride("separation", (int)(4 * scaleFactor));

        LabelSettings labelSettings = new LabelSettings();
        labelSettings.FontSize = (int)(12 * scaleFactor); // M3 Label Medium
        
        // Dynamic active colors
        Color activeTextCol = CurrentTheme.OnSurface;
        Color inactiveTextCol = CurrentTheme.OnSurfaceVariant;
        labelSettings.FontColor = inactiveTextCol.Lerp(activeTextCol, _activePercent);
        _label.LabelSettings = labelSettings;

        Color activeIconCol = CurrentTheme.OnSecondaryContainer;
        Color inactiveIconCol = CurrentTheme.OnSurfaceVariant;
        _iconRect.SelfModulate = inactiveIconCol.Lerp(activeIconCol, _activePercent);

        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null || _capsuleFrame == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        // Draw active capsule behind icon (64dp wide x 32dp high, rounded corners)
        if (_activePercent > 0.0f)
        {
            StyleBoxFlat capsuleBox = new StyleBoxFlat();
            capsuleBox.SetCornerRadiusAll((int)(16 * scaleFactor)); // Rounded capsule (32 / 2) scaled

            Color capCol = CurrentTheme.SecondaryContainer;
            capCol.A = _activePercent; // Fade overlay
            capsuleBox.BgColor = capCol;

            Rect2 capsuleRect = new Rect2(
                _capsuleFrame.GlobalPosition - GlobalPosition, 
                _capsuleFrame.Size
            );

            DrawStyleBox(capsuleBox, capsuleRect);
        }
    }
}
