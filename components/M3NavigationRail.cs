using Godot;
using System;
using System.Collections.Generic;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Navigation Rail (Side Navigation).
/// Sits on the left side, holding 3-5 items with capsule active indicators vertically.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3NavigationRail : Control
{
    private VBoxContainer _vbox;
    private int _selectedIndex = 0;
    private readonly List<string> _items = new() { "Home", "Explore", "Settings" };
    private readonly List<M3NavigationRailItem> _childItems = new();

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

    private Control _topSpacer;

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
        _vbox = new VBoxContainer();
        _vbox.SetAnchorsPreset(LayoutPreset.FullRect);
        _vbox.Alignment = BoxContainer.AlignmentMode.Begin;
        _vbox.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        _vbox.SizeFlagsVertical = SizeFlags.ExpandFill;
        AddChild(_vbox);

        // Add a top spacer margin inside vbox
        _topSpacer = new Control();
        _vbox.AddChild(_topSpacer);

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
        CustomMinimumSize = new Vector2(80, 200) * scaleFactor; // M3 rail width is 80dp scaled
        
        if (_vbox != null)
        {
            _vbox.AddThemeConstantOverride("separation", (int)(16 * scaleFactor));
        }

        if (_topSpacer != null)
        {
            _topSpacer.CustomMinimumSize = new Vector2(0, (int)(16 * scaleFactor));
        }

        RebuildRail();
        QueueRedraw();
    }

    private void RebuildRail()
    {
        if (_vbox == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        // Clear existing items (skipping top spacer)
        for (int i = _childItems.Count - 1; i >= 0; i--)
        {
            _childItems[i].QueueFree();
        }
        _childItems.Clear();

        // Add rail items
        for (int i = 0; i < _items.Count; i++)
        {
            int currentIndex = i;
            var itemNode = new M3NavigationRailItem(i, _items[i], null);
            itemNode.CustomMinimumSize = new Vector2(80, 56) * scaleFactor;
            itemNode.Pressed += () => SelectedIndex = currentIndex;
            _vbox.AddChild(itemNode);
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

        // Draw rail background panel
        StyleBoxFlat railPanel = new StyleBoxFlat();
        railPanel.BgColor = CurrentTheme.SurfaceVariant;
        railPanel.BorderWidthRight = (int)(1 * scaleFactor);
        railPanel.BorderColor = CurrentTheme.OutlineVariant;

        DrawStyleBox(railPanel, new Rect2(Vector2.Zero, Size));
    }
}

/// <summary>
/// Sub-component representing a single tab item in the side navigation rail.
/// </summary>
internal partial class M3NavigationRailItem : Control
{
    private readonly int _index;
    private readonly string _labelTxt;
    private readonly Texture2D _iconTexture;

    private VBoxContainer _vbox;
    private Control _capsuleFrame;
    private TextureRect _iconRect;
    private Label _label;

    private float _activePercent = 0.0f; // Active tween interpolation factor

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

    public M3NavigationRailItem(int index, string label, Texture2D icon)
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

        _capsuleFrame.CustomMinimumSize = new Vector2(56, 32) * scaleFactor; // Slightly smaller capsule for rail
        _iconRect.CustomMinimumSize = new Vector2(24, 24) * scaleFactor;

        _vbox.AddThemeConstantOverride("separation", (int)(4 * scaleFactor));

        LabelSettings labelSettings = new LabelSettings();
        labelSettings.FontSize = (int)(11 * scaleFactor); // M3 Label Small for vertical density
        
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

        if (_activePercent > 0.0f)
        {
            StyleBoxFlat capsuleBox = new StyleBoxFlat();
            capsuleBox.SetCornerRadiusAll((int)(16 * scaleFactor));

            Color capCol = CurrentTheme.SecondaryContainer;
            capCol.A = _activePercent;
            capsuleBox.BgColor = capCol;

            Rect2 capsuleRect = new Rect2(
                _capsuleFrame.GlobalPosition - GlobalPosition, 
                _capsuleFrame.Size
            );

            DrawStyleBox(capsuleBox, capsuleRect);
        }
    }
}
