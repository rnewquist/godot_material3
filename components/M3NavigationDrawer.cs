using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

public enum M3DrawerAnchor
{
    Left,
    Right
}

/// <summary>
/// A native Godot Control representing a Material 3 Navigation Drawer.
/// Slides dynamically from the screen edge, managing elevation backgrounds and shapes.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3NavigationDrawer : M3BaseComponent
{
    private bool _isOpen = false;
    private M3DrawerAnchor _anchor = M3DrawerAnchor.Left;
    private float _slidePercent = 0.0f; // 0.0 = fully hidden, 1.0 = fully open
    private Control _contentPanel;

    [Signal]
    public delegate void DrawerStateChangedEventHandler(bool isOpen);

    /// <summary>
    /// Gets or sets whether the drawer is open (slid into view).
    /// </summary>
    [Export]
    public bool IsOpen
    {
        get => _isOpen;
        set
        {
            if (_isOpen != value)
            {
                _isOpen = value;
                AnimateDrawerState();
                EmitSignal(SignalName.DrawerStateChanged, _isOpen);
            }
        }
    }

    /// <summary>
    /// Gets or sets whether the drawer anchors on the Left or Right screen boundary.
    /// </summary>
    [Export]
    public new M3DrawerAnchor Anchor
    {
        get => _anchor;
        set
        {
            _anchor = value;
            ResetLayout();
        }
    }

    /// <summary>
    /// Driven by Tweens to update positioning.
    /// Implements Property Redraw Pattern by calling QueueRedraw.
    /// </summary>
    private float SlidePercent
    {
        get => _slidePercent;
        set
        {
            _slidePercent = value;
            UpdateDrawerPosition();
            QueueRedraw();
        }
    }

    public override void _Ready()
    {
        // Ignore mouse inputs on the full-screen parent wrapper so clicks pass through when closed
        MouseFilter = MouseFilterEnum.Ignore;

        // Content Panel to hold children within safe boundary margins, blocks clicks inside the drawer
        _contentPanel = new Control();
        _contentPanel.ClipContents = true;
        _contentPanel.MouseFilter = MouseFilterEnum.Stop;
        AddChild(_contentPanel);

        base._Ready();
    }

    private void ResetLayout()
    {
        if (_contentPanel == null) return;

        // Cover parent screen vertical height, absolute fixed width of 360px scaled
        float scaledWidth = 360.0f * ScaleFactor;
        _contentPanel.Size = new Vector2(scaledWidth, Size.Y);
        UpdateDrawerPosition();
    }

    private void AnimateDrawerState()
    {
        float target = _isOpen ? 1.0f : 0.0f;
        var tween = CreateTween();
        
        // M3 standard motion curve: decelerate (DecelCurve = easeOutQuad)
        tween.TweenProperty(this, "SlidePercent", target, 0.25f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);
    }

    private void UpdateDrawerPosition()
    {
        if (_contentPanel == null) return;

        float scaledWidth = 360.0f * ScaleFactor; // Fixed standard M3 width scaled
        float offscreenOffset = scaledWidth;
        float currentOffset = 0.0f;

        if (_anchor == M3DrawerAnchor.Left)
        {
            currentOffset = Mathf.Lerp(-offscreenOffset, 0.0f, _slidePercent);
            _contentPanel.Position = new Vector2(currentOffset, 0.0f);
        }
        else
        {
            currentOffset = Mathf.Lerp(offscreenOffset, 0.0f, _slidePercent);
            _contentPanel.Position = new Vector2(Size.X - scaledWidth + currentOffset, 0.0f);
        }
    }

    protected override void ApplyTheme()
    {
        CustomMinimumSize = new Vector2(360, 200) * ScaleFactor;
        ResetLayout();
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null || _contentPanel == null) return;

        // Draw standard elevated dynamic surface background panel matching slide geometry
        StyleBoxFlat drawerBox = new StyleBoxFlat();
        drawerBox.BgColor = CurrentTheme.SurfaceVariant;

        // Large 16dp rounded corners on the protruding vertical side of the drawer scaled
        drawerBox.SetCornerRadiusAll(0);
        if (_anchor == M3DrawerAnchor.Left)
        {
            drawerBox.CornerRadiusTopRight = (int)(CurrentTheme.CornerLarge * ScaleFactor);
            drawerBox.CornerRadiusBottomRight = (int)(CurrentTheme.CornerLarge * ScaleFactor);
        }
        else
        {
            drawerBox.CornerRadiusTopLeft = (int)(CurrentTheme.CornerLarge * ScaleFactor);
            drawerBox.CornerRadiusBottomLeft = (int)(CurrentTheme.CornerLarge * ScaleFactor);
        }

        // Slight elevation border stroke scaled
        drawerBox.BorderWidthRight = _anchor == M3DrawerAnchor.Left ? (int)(1 * ScaleFactor) : 0;
        drawerBox.BorderWidthLeft = _anchor == M3DrawerAnchor.Right ? (int)(1 * ScaleFactor) : 0;
        drawerBox.BorderColor = CurrentTheme.OutlineVariant;

        // Draw stylebox relative to content panel boundary
        DrawStyleBox(drawerBox, new Rect2(_contentPanel.Position, _contentPanel.Size));
    }
}
