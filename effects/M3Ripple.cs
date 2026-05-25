using Godot;
using System;

namespace Material3.Effects;

/// <summary>
/// A procedural vector-drawn control implementing the Material 3 Ripple feedback animation.
/// To be instantiated as a child inside any interactive control.
/// </summary>
public partial class M3Ripple : Control
{
    private float _radius = 0.0f;
    private float _opacity = 0.0f;
    private Vector2 _center = Vector2.Zero;
    private Color _rippleColor = Color.FromHtml("#FFFFFF");

    /// <summary>
    /// The current radius of the vector ripple circle.
    /// Triggers a canvas redraw upon mutation.
    /// </summary>
    public float Radius
    {
        get => _radius;
        set
        {
            _radius = value;
            QueueRedraw();
        }
    }

    /// <summary>
    /// The current opacity of the vector ripple.
    /// Triggers a canvas redraw upon mutation.
    /// </summary>
    public float Opacity
    {
        get => _opacity;
        set
        {
            _opacity = value;
            QueueRedraw();
        }
    }

    /// <summary>
    /// Set the base color of the ripple (typically derived from dynamic text/icon colors).
    /// </summary>
    public Color RippleColor
    {
        get => _rippleColor;
        set
        {
            _rippleColor = value;
            QueueRedraw();
        }
    }

    public override void _Ready()
    {
        // Enforce full coverage inside parent and disable focus/mouse consumption
        MouseFilter = MouseFilterEnum.Ignore;
        SetAnchorsPreset(LayoutPreset.FullRect);
        ClipChildren = ClipChildrenMode.Only;
    }

    /// <summary>
    /// Initiates a ripple expansion tween starting at the specified local click coordinates.
    /// </summary>
    /// <param name="localClickPosition">The relative coordinate of the mouse press.</param>
    public void TriggerRipple(Vector2 localClickPosition)
    {
        _center = localClickPosition;
        
        // Calculate maximum target radius (distance to furthest corner of bounding rect)
        float w = Size.X;
        float h = Size.Y;
        float distTL = _center.DistanceTo(new Vector2(0, 0));
        float distTR = _center.DistanceTo(new Vector2(w, 0));
        float distBL = _center.DistanceTo(new Vector2(0, h));
        float distBR = _center.DistanceTo(new Vector2(w, h));
        float targetRadius = Math.Max(Math.Max(distTL, distTR), Math.Max(distBL, distBR));

        // Reset state
        Radius = 0.0f;
        Opacity = 0.12f;

        // Animate radius expansion (conforming to M3 standard deceleration curve)
        var tween = CreateTween().SetParallel(true);
        
        // standard M3 Easing: cubic-bezier(0.2, 0, 0, 1) -> approximated by QuadOut
        tween.TweenProperty(this, "Radius", targetRadius, 0.225f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);

        // Fade out transition
        tween.TweenProperty(this, "Opacity", 0.0f, 0.350f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out)
             .SetDelay(0.05f);
    }

    public override void _Draw()
    {
        if (Opacity > 0.0f && Radius > 0.0f)
        {
            Color finalColor = RippleColor;
            finalColor.A = Opacity;
            DrawCircle(_center, Radius, finalColor);
        }
    }
}
