using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

/// <summary>
/// A single item representing a Material 3 Tab used inside a TabBar.
/// Handles active highlight transitions and ripple interactive layers.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3Tab : M3BaseComponent
{
    private string _text = "Tab Item";
    private bool _isActive = false;
    private float _activePercent = 0.0f; // Active interpolation tween

    private Label _labelNode;
    private Control _indicatorLine;

    public event Action Pressed;

    [Export]
    public string Text
    {
        get => _text;
        set
        {
            _text = value;
            if (_labelNode != null) _labelNode.Text = _text;
        }
    }

    [Export]
    public bool IsActive
    {
        get => _isActive;
        set
        {
            _isActive = value;
            AnimateSelectionState();
        }
    }

    public override void _Ready()
    {
        CustomMinimumSize = new Vector2(90, 48); // Standard M3 tab height: 48dp

        // Label Large: standard M3 tab text scale
        _labelNode = new Label();
        _labelNode.Text = _text;
        _labelNode.HorizontalAlignment = HorizontalAlignment.Center;
        _labelNode.VerticalAlignment = VerticalAlignment.Center;
        _labelNode.SetAnchorsPreset(LayoutPreset.FullRect);
        _labelNode.MouseFilter = MouseFilterEnum.Ignore;
        AddChild(_labelNode);

        // Underlying active capsule line
        _indicatorLine = new Control();
        _indicatorLine.CustomMinimumSize = new Vector2(40, 3); // 3dp thickness capsule
        _indicatorLine.SetAnchorsPreset(LayoutPreset.BottomWide);
        _indicatorLine.OffsetBottom = 0;
        _indicatorLine.OffsetTop = -3;
        _indicatorLine.MouseFilter = MouseFilterEnum.Ignore;
        AddChild(_indicatorLine);

        base._Ready();
        ApplyItemStyle();
    }

    private void AnimateSelectionState()
    {
        float target = _isActive ? 1.0f : 0.0f;
        var tween = CreateTween();
        
        // Fast dynamic M3 selection slide-fade
        tween.TweenProperty(this, "_activePercent", target, 0.15f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);
        
        tween.Finished += ApplyItemStyle;
    }

    public override void _GuiInput(InputEvent @event)
    {
        base._GuiInput(@event);

        if (@event is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            if (!mouseEvent.Pressed && IsHoveredState())
            {
                Pressed?.Invoke();
            }
        }
    }

    protected override void ApplyTheme()
    {
        CustomMinimumSize = new Vector2(90, 48) * ScaleFactor; // Standard M3 tab height: 48dp scaled
        if (RippleNode != null && CurrentTheme != null)
        {
            RippleNode.RippleColor = CurrentTheme.Primary;
        }
        ApplyItemStyle();
    }

    private void ApplyItemStyle()
    {
        if (CurrentTheme == null || _labelNode == null) return;

        // Active tab label settings: Lerp from OnSurfaceVariant to Primary
        LabelSettings labelSettings = new LabelSettings();
        labelSettings.FontSize = (int)(14 * ScaleFactor); // Label Large scaled
        
        Color activeCol = CurrentTheme.Primary;
        Color inactiveCol = CurrentTheme.OnSurfaceVariant;
        labelSettings.FontColor = inactiveCol.Lerp(activeCol, _activePercent);
        _labelNode.LabelSettings = labelSettings;

        QueueRedraw();
    }

    public override void _Draw()
    {
        if (CurrentTheme == null || _indicatorLine == null) return;

        if (_activePercent > 0.0f)
        {
            float scaleFactor = ScaleFactor;

            // Draw procedural active indicator line at the bottom
            StyleBoxFlat indicatorBox = new StyleBoxFlat();
            indicatorBox.BgColor = CurrentTheme.Primary;
            
            // Highly rounded pill ends
            indicatorBox.SetCornerRadiusAll((int)(2 * scaleFactor));

            // Dynamically scale/expand the indicator pill horizontally as it activates!
            float baseWidth = 40.0f * scaleFactor;
            float thickness = 3.0f * scaleFactor;
            float targetWidth = Mathf.Lerp(10.0f * scaleFactor, baseWidth, _activePercent);
            float offset = (Size.X - targetWidth) / 2.0f;

            Rect2 indicatorRect = new Rect2(
                offset, 
                Size.Y - thickness, 
                targetWidth, 
                thickness
            );

            DrawStyleBox(indicatorBox, indicatorRect);
        }
    }
}
