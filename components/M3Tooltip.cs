using Godot;
using System;
using Material3.Core;

namespace Material3.Components;

public enum M3TooltipPosition
{
    Above,
    Below,
    Left,
    Right
}

/// <summary>
/// A native Godot Control representing a Material 3 Tooltip.
/// Binds dynamically to target hover signals, positioning and fading overlays smoothly.
/// </summary>
[Tool]
[GlobalClass]
public partial class M3Tooltip : Control
{
    private NodePath _targetPath;
    private Control _targetNode;
    private M3TooltipPosition _tooltipPosition = M3TooltipPosition.Above;
    private string _text = "Tooltip Helper text";
    private bool _isVisible = false;
    private Label _labelNode;
    private PanelContainer _panelContainer;
    private MarginContainer _marginContainer;
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
    public NodePath TargetPath
    {
        get => _targetPath;
        set
        {
            _targetPath = value;
            BindToTarget();
        }
    }

    [Export]
    public M3TooltipPosition TooltipPosition
    {
        get => _tooltipPosition;
        set { _tooltipPosition = value; RepositionTooltip(); }
    }

    [Export]
    public string Text
    {
        get => _text;
        set
        {
            _text = value;
            if (_labelNode != null) _labelNode.Text = _text;
            RepositionTooltip();
        }
    }

    public override void _Ready()
    {
        // Build panel container child
        _panelContainer = new PanelContainer();
        _panelContainer.MouseFilter = MouseFilterEnum.Ignore;
        AddChild(_panelContainer);

        // Build margin child inside panel
        _marginContainer = new MarginContainer();
        _panelContainer.AddChild(_marginContainer);

        // Build label inside margin
        _labelNode = new Label();
        _labelNode.Text = _text;
        _labelNode.MouseFilter = MouseFilterEnum.Ignore;
        _marginContainer.AddChild(_labelNode);

        // Hide initially
        Modulate = new Color(1, 1, 1, 0);
        Scale = new Vector2(0.8f, 0.8f);
        Visible = false;

        BindToTarget();
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged += ApplyTooltipStyle;
        }
        ApplyTooltipStyle();
    }

    public override void _ExitTree()
    {
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ThemeChanged -= ApplyTooltipStyle;
        }
        UnbindTarget();
    }

    private void BindToTarget()
    {
        UnbindTarget();

        if (IsInsideTree() && _targetPath != null && !string.IsNullOrEmpty(_targetPath.ToString()))
        {
            _targetNode = GetNodeOrNull<Control>(_targetPath);
            if (_targetNode != null)
            {
                _targetNode.MouseEntered += OnTargetMouseEntered;
                _targetNode.MouseExited += OnTargetMouseExited;
            }
        }
    }

    private void UnbindTarget()
    {
        if (_targetNode != null && GodotObject.IsInstanceValid(_targetNode))
        {
            _targetNode.MouseEntered -= OnTargetMouseEntered;
            _targetNode.MouseExited -= OnTargetMouseExited;
        }
        _targetNode = null;
    }

    private void OnTargetMouseEntered()
    {
        ShowTooltip();
    }

    private void OnTargetMouseExited()
    {
        HideTooltip();
    }

    public void ShowTooltip()
    {
        _isVisible = true;
        Visible = true;
        RepositionTooltip();

        if (_activeTween != null) _activeTween.Kill();
        _activeTween = CreateTween().SetParallel(true);
        
        // Scale and fade-in matching standard M3 motion specs
        _activeTween.TweenProperty(this, "modulate:a", 1.0f, 0.15f)
                    .SetTrans(Tween.TransitionType.Quad)
                    .SetEase(Tween.EaseType.Out);
        _activeTween.TweenProperty(this, "scale", Vector2.One, 0.15f)
                    .SetTrans(Tween.TransitionType.Quad)
                    .SetEase(Tween.EaseType.Out);
    }

    public void HideTooltip()
    {
        _isVisible = false;

        if (_activeTween != null) _activeTween.Kill();
        _activeTween = CreateTween().SetParallel(true);

        _activeTween.TweenProperty(this, "modulate:a", 0.0f, 0.12f)
                    .SetTrans(Tween.TransitionType.Quad)
                    .SetEase(Tween.EaseType.In);
        _activeTween.TweenProperty(this, "scale", new Vector2(0.8f, 0.8f), 0.12f)
                    .SetTrans(Tween.TransitionType.Quad)
                    .SetEase(Tween.EaseType.In);

        _activeTween.Finished += () =>
        {
            if (!_isVisible) Visible = false;
        };
    }

    private void RepositionTooltip()
    {
        if (_targetNode == null || _panelContainer == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        // Auto-sizing calculations
        _panelContainer.ResetSize();
        Vector2 targetSize = _targetNode.Size;
        Vector2 targetGlobalPos = _targetNode.GlobalPosition;
        Vector2 tooltipSize = _panelContainer.Size;

        Vector2 parentGlobalPos = (GetParent() as Control)?.GlobalPosition ?? Vector2.Zero;
        Vector2 localTargetPos = targetGlobalPos - parentGlobalPos;
        Vector2 targetCenter = localTargetPos + (targetSize / 2.0f);
        Vector2 placement = Vector2.Zero;

        float offset = 8.0f * scaleFactor;

        switch (_tooltipPosition)
        {
            case M3TooltipPosition.Above:
                placement = new Vector2(targetCenter.X - (tooltipSize.X / 2.0f), localTargetPos.Y - tooltipSize.Y - offset);
                break;
            case M3TooltipPosition.Below:
                placement = new Vector2(targetCenter.X - (tooltipSize.X / 2.0f), localTargetPos.Y + targetSize.Y + offset);
                break;
            case M3TooltipPosition.Left:
                placement = new Vector2(localTargetPos.X - tooltipSize.X - offset, targetCenter.Y - (tooltipSize.Y / 2.0f));
                break;
            case M3TooltipPosition.Right:
                placement = new Vector2(localTargetPos.X + targetSize.X + offset, targetCenter.Y - (tooltipSize.Y / 2.0f));
                break;
        }

        // Clamp inside parent control view limits to prevent cutting off, safe against early uninitialized parent sizes
        Vector2 parentSize = (GetParent() as Control)?.Size ?? (GetViewport()?.GetVisibleRect().Size ?? new Vector2(1024, 768));
        float clampMargin = 4.0f * scaleFactor;
        
        float minX = clampMargin;
        float maxX = parentSize.X - tooltipSize.X - clampMargin;
        if (minX <= maxX)
        {
            placement.X = Math.Clamp(placement.X, minX, maxX);
        }

        float minY = clampMargin;
        float maxY = parentSize.Y - tooltipSize.Y - clampMargin;
        if (minY <= maxY)
        {
            placement.Y = Math.Clamp(placement.Y, minY, maxY);
        }

        Position = placement;
        PivotOffset = tooltipSize / 2.0f; // Scale pivot at center
    }

    private void ApplyTooltipStyle()
    {
        if (CurrentTheme == null || _panelContainer == null || _labelNode == null || _marginContainer == null) return;

        float scaleFactor = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        // Apply scale factor to internal margins
        _marginContainer.AddThemeConstantOverride("margin_left", (int)(8 * scaleFactor));
        _marginContainer.AddThemeConstantOverride("margin_top", (int)(4 * scaleFactor));
        _marginContainer.AddThemeConstantOverride("margin_right", (int)(8 * scaleFactor));
        _marginContainer.AddThemeConstantOverride("margin_bottom", (int)(4 * scaleFactor));

        // Small (8dp) rounded corners matching M3 specs scaled
        StyleBoxFlat styleBox = new StyleBoxFlat();
        styleBox.BgColor = CurrentTheme.SurfaceVariant;
        styleBox.SetCornerRadiusAll((int)(CurrentTheme.CornerExtraSmall * scaleFactor));
        _panelContainer.AddThemeStyleboxOverride("panel", styleBox);

        // Label Settings: Size 11px (M3 Body Small/Label Small) scaled
        LabelSettings labelSettings = new LabelSettings();
        labelSettings.FontSize = (int)(11 * scaleFactor);
        labelSettings.FontColor = CurrentTheme.OnSurfaceVariant;
        _labelNode.LabelSettings = labelSettings;

        RepositionTooltip();
    }
}
