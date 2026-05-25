using Godot;
using System;
using System.Collections.Generic;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A native Godot Control representing a Material 3 Tab Bar.
/// Manages a horizontal list of Tabs, routing select events and maintaining active state.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3TabBar : Control
{
    private HBoxContainer _hbox;
    private int _selectedIndex = 0;
    private readonly List<string> _items = new() { "Tab 1", "Tab 2", "Tab 3" };
    private readonly List<M3Tab> _childTabs = new();

    [Signal]
    public delegate void TabSelectedEventHandler(int index);

    [Export]
    public int SelectedIndex
    {
        get => _selectedIndex;
        set
        {
            if (value >= 0 && value < _childTabs.Count && _selectedIndex != value)
            {
                _selectedIndex = value;
                UpdateTabSelection();
                EmitSignal(SignalName.TabSelected, _selectedIndex);
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
        CustomMinimumSize = new Vector2(200, 48) * scaleFactor; // Standard M3 height: 48dp scaled
        RebuildTabs();
        QueueRedraw();
    }

    private void RebuildTabs()
    {
        if (_hbox == null) return;

        // Clear existing
        foreach (var tab in _childTabs)
        {
            tab.QueueFree();
        }
        _childTabs.Clear();

        // Build child tabs
        for (int i = 0; i < _items.Count; i++)
        {
            int currentIndex = i;
            var tabNode = new M3Tab();
            tabNode.Text = _items[i];
            tabNode.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            tabNode.SizeFlagsVertical = SizeFlags.ExpandFill;
            tabNode.Pressed += () => SelectedIndex = currentIndex;
            
            _hbox.AddChild(tabNode);
            _childTabs.Add(tabNode);
        }

        UpdateTabSelection();
    }

    private void UpdateTabSelection()
    {
        for (int i = 0; i < _childTabs.Count; i++)
        {
            _childTabs[i].IsActive = (i == _selectedIndex);
        }
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        // Draw flat background with divider line at the bottom
        StyleBoxFlat tabBackground = new StyleBoxFlat();
        tabBackground.BgColor = CurrentTheme.Surface;
        tabBackground.BorderWidthBottom = (int)(1 * scaleFactor);
        tabBackground.BorderColor = CurrentTheme.OutlineVariant;

        DrawStyleBox(tabBackground, new Rect2(Vector2.Zero, Size));
    }
}
