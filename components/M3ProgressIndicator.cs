using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

public enum M3ProgressType
{
    Linear,
    Circular
}

/// <summary>
/// A native Godot Control representing a Material 3 Progress Indicator.
/// Supports Linear/Circular shapes and Determinate/Indeterminate load states.
/// </summary>
[Tool]
[GlobalClass, Icon("res://icon.svg")]
public partial class M3ProgressIndicator : Control
{
    private M3ProgressType _progressType = M3ProgressType.Linear;
    private bool _indeterminate = false;
    private float _progressValue = 0.0f; // 0.0f to 1.0f
    private float _animProgress = 0.0f;  // Driven by indeterminate Tweens
    private Tween _activeTween;

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

    [Export]
    public M3ProgressType ProgressType
    {
        get => _progressType;
        set { _progressType = value; ResetLayout(); }
    }

    [Export]
    public bool Indeterminate
    {
        get => _indeterminate;
        set
        {
            if (_indeterminate != value)
            {
                _indeterminate = value;
                ToggleAnimation();
            }
        }
    }

    [Export]
    public float ProgressValue
    {
        get => _progressValue;
        set
        {
            _progressValue = Math.Clamp(value, 0.0f, 1.0f);
            if (!_indeterminate) QueueRedraw();
        }
    }

    /// <summary>
    /// Property driven by Tweens.
    /// Implements Property Redraw Pattern by calling QueueRedraw.
    /// </summary>
    private float AnimProgress
    {
        get => _animProgress;
        set { _animProgress = value; QueueRedraw(); }
    }

    public override void _Ready()
    {
        ResetLayout();
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged += QueueRedraw;
        }
        ToggleAnimation();
    }

    public override void _ExitTree()
    {
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged -= QueueRedraw;
        }
        KillAnimation();
    }

    private float ScaleFactor => M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

    private void ResetLayout()
    {
        if (_progressType == M3ProgressType.Linear)
        {
            CustomMinimumSize = new Vector2(100, 4) * ScaleFactor;
        }
        else
        {
            CustomMinimumSize = new Vector2(40, 40) * ScaleFactor;
        }
        QueueRedraw();
    }

    private void ToggleAnimation()
    {
        KillAnimation();

        if (_indeterminate && IsInsideTree())
        {
            _activeTween = CreateTween().SetLoops();
            
            // Loop from 0.0f to 1.0f infinitely representing rotation/expand offset
            _activeTween.TweenProperty(this, "AnimProgress", 1.0f, 1.5f)
                        .SetTrans(Tween.TransitionType.Linear)
                        .SetEase(Tween.EaseType.InOut);
        }
        else
        {
            AnimProgress = 0.0f;
        }
    }

    private void KillAnimation()
    {
        if (_activeTween != null)
        {
            _activeTween.Kill();
            _activeTween = null;
        }
    }

    public override void _Draw()
    {
        if (CurrentTheme == null) return;

        if (_progressType == M3ProgressType.Linear)
        {
            DrawLinearProgress();
        }
        else
        {
            DrawCircularProgress();
        }
    }

    private void DrawLinearProgress()
    {
        float centerY = Size.Y / 2.0f;
        float h = 4.0f * ScaleFactor; // 4dp height scaled

        // 1. Draw track
        Vector2 start = new Vector2(0, centerY);
        Vector2 end = new Vector2(Size.X, centerY);
        DrawLine(start, end, CurrentTheme.SurfaceVariant, h, true);

        // 2. Draw active bar
        if (_indeterminate)
        {
            // Draw dual bouncing lines mapping standard indeterminate spec
            float w = Size.X;
            float offset1 = _animProgress * w;
            float barWidth = w * 0.40f;
            float x1 = (offset1) % (w + barWidth) - barWidth;
            float x2 = x1 + barWidth;

            x1 = Math.Clamp(x1, 0, w);
            x2 = Math.Clamp(x2, 0, w);

            if (x1 < x2)
            {
                DrawLine(new Vector2(x1, centerY), new Vector2(x2, centerY), CurrentTheme.Primary, h, true);
            }
        }
        else
        {
            float fillWidth = Size.X * _progressValue;
            if (fillWidth > 0.0f)
            {
                DrawLine(start, new Vector2(fillWidth, centerY), CurrentTheme.Primary, h, true);
            }
        }
    }

    private void DrawCircularProgress()
    {
        Vector2 center = Size / 2.0f;
        float radius = (Math.Min(Size.X, Size.Y) / 2.0f) - 4.0f * ScaleFactor; // Padding margin scaled
        float width = 4.0f * ScaleFactor; // 4dp thickness scaled

        // 1. Draw background track circle
        DrawArc(center, radius, 0, Mathf.Tau, 64, CurrentTheme.SurfaceVariant, width, true);

        // 2. Draw active arc
        if (_indeterminate)
        {
            // Rotate circular arc dynamically based on loop animation
            float angleOffset = _animProgress * Mathf.Tau;
            float arcLength = Mathf.Pi * 1.5f * (0.5f + 0.5f * Mathf.Sin(_animProgress * Mathf.Pi)); // Dynamically expand/contract
            DrawArc(center, radius, angleOffset, angleOffset + arcLength, 64, CurrentTheme.Primary, width, true);
        }
        else
        {
            float arcLength = _progressValue * Mathf.Tau;
            if (arcLength > 0.0f)
            {
                // M3 starts arc from top (-90 degrees / -Pi/2)
                float startAngle = -Mathf.Pi / 2.0f;
                DrawArc(center, radius, startAngle, startAngle + arcLength, 64, CurrentTheme.Primary, width, true);
            }
        }
    }
}
