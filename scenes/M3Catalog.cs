using Godot;
using System;
using Material3.Core;
using Material3.Components;

namespace Material3.Scenes;

/// <summary>
/// Driver class for the Material 3 Interactive Catalog Scene.
/// Connects dynamic theme selectors, HSL seed editors, and form-factor viewport emulators.
/// </summary>
public partial class M3Catalog : Control
{
    private PanelContainer _emuViewportFrame;
    private SubViewport _subViewport;
    private bool _isAutoRes = false;
    
    // Seed Color Constants
    private static readonly Color ColorViolet = Color.FromHtml("#6750A4");
    private static readonly Color ColorEmerald = Color.FromHtml("#00875A");
    private static readonly Color ColorAmber = Color.FromHtml("#B35B00");
    private static readonly Color ColorCrimson = Color.FromHtml("#B3261E");

    public override void _Ready()
    {
        // Bind UI Elements
        _emuViewportFrame = GetNode<PanelContainer>("%ViewportFrame");
        _subViewport = GetNode<SubViewport>("%DemoViewport");

        // Seed Color selectors
        GetNode<M3Button>("%BtnSeedViolet").Pressed += () => ChangeSeedColor(ColorViolet);
        GetNode<M3Button>("%BtnSeedEmerald").Pressed += () => ChangeSeedColor(ColorEmerald);
        GetNode<M3Button>("%BtnSeedAmber").Pressed += () => ChangeSeedColor(ColorAmber);
        GetNode<M3Button>("%BtnSeedCrimson").Pressed += () => ChangeSeedColor(ColorCrimson);

        // Radio Button mutually exclusive grouping
        var radio1 = GetNode<M3RadioButton>("%Radio1");
        var radio2 = GetNode<M3RadioButton>("%Radio2");
        radio1.SelectedChanged += (isSelected) => { if (isSelected) radio2.Selected = false; };
        radio2.SelectedChanged += (isSelected) => { if (isSelected) radio1.Selected = false; };

        // Theme Mode switches
        GetNode<M3Switch>("%SwitchDarkMode").CheckedChanged += (isDarkMode) =>
        {
            M3ThemeManager.Instance.IsDarkMode = isDarkMode;
        };

        // Emulator Screen Resolutions
        GetNode<M3Button>("%BtnResDesktop").Pressed += () => SetEmulatorResolution(new Vector2(1000, 600), "Desktop Emulator", 1.0f);
        GetNode<M3Button>("%BtnResMobile").Pressed += () => SetEmulatorResolution(new Vector2(360, 640), "Mobile Portrait Emulator", 1.6f);
        GetNode<M3Button>("%BtnResTablet").Pressed += () => SetEmulatorResolution(new Vector2(768, 576), "Tablet Emulator", 1.25f);
        GetNode<M3Button>("%BtnResAuto").Pressed += SetEmulatorResolutionAuto;

        // Viewport resize wiring
        var viewport = GetViewport();
        if (viewport != null)
        {
            viewport.SizeChanged += OnViewportSizeChanged;
        }

        GD.Print("CMD ARGS: " + string.Join(", ", OS.GetCmdlineArgs()));
        GD.Print("USER ARGS: " + string.Join(", ", OS.GetCmdlineUserArgs()));

        // Trigger visual audit only if the 'audit' argument is explicitly passed
        bool shouldAudit = false;
        foreach (string arg in OS.GetCmdlineArgs())
        {
            if (arg.Contains("audit"))
            {
                shouldAudit = true;
                break;
            }
        }
        foreach (string arg in OS.GetCmdlineUserArgs())
        {
            if (arg.Contains("audit"))
            {
                shouldAudit = true;
                break;
            }
        }
        
        if (shouldAudit)
        {
            RunVisualAuditPipeline();
        }
    }

    /// <summary>
    /// Programmatic visual audit pipeline that cycles through every combination of resolution,
    /// seed color, and theme mode, capturing and saving vector screenshots to disk.
    /// </summary>
    public async void RunVisualAuditPipeline()
    {
        GD.Print("=== Starting Automated Visual Audit Pipeline ===");
        
        // Wait for system and shaders to stabilize
        await ToSignal(GetTree().CreateTimer(0.5f), "timeout");

        string dirPath = "res://screenshots";
        DirAccess.MakeDirAbsolute(dirPath);

        // Safely determine dynamic native screen dimensions and DPI scale of the running device
        Vector2I nativeSize = DisplayServer.ScreenGetSize();
        if (nativeSize.X <= 0 || nativeSize.Y <= 0)
        {
            nativeSize = new Vector2I(1280, 720);
        }
        float nativeScale = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;

        Vector2[] resolutions = new Vector2[] { new(1000, 600), new(360, 640), new(768, 576), new(nativeSize.X, nativeSize.Y) };
        string[] resNames = new string[] { "desktop", "mobile", "tablet", "native" };
        float[] scales = new float[] { 1.0f, 1.6f, 1.25f, nativeScale };

        bool[] modes = new bool[] { false, true };
        string[] modeNames = new string[] { "light", "dark" };

        Color[] seeds = new Color[] { ColorViolet, ColorEmerald, ColorAmber };
        string[] seedNames = new string[] { "violet", "emerald", "amber" };

        for (int r = 0; r < resolutions.Length; r++)
        {
            SetEmulatorResolution(resolutions[r], resNames[r], scales[r]);
            // Allow container layout reflows to settle
            await ToSignal(GetTree().CreateTimer(0.2f), "timeout");

            for (int m = 0; m < modes.Length; m++)
            {
                M3ThemeManager.Instance.IsDarkMode = modes[m];
                await ToSignal(GetTree().CreateTimer(0.1f), "timeout");

                for (int s = 0; s < seeds.Length; s++)
                {
                    ChangeSeedColor(seeds[s]);

                    // Trigger dynamic drawer and tooltip on desktop resolution to capture their visual fidelity
                    var drawer = GetNode<M3NavigationDrawer>("%Drawer");
                    var tooltip = GetNode<M3Tooltip>("%Tooltip1");
                    if (resNames[r] == "desktop" || resNames[r] == "native")
                    {
                        drawer.IsOpen = true;
                        tooltip.ShowTooltip();
                    }
                    else
                    {
                        drawer.IsOpen = false;
                        tooltip.HideTooltip();
                    }

                    // Allow tweens and colors to resolve
                    await ToSignal(GetTree().CreateTimer(0.3f), "timeout");

                    // Force rendering frame tick update
                    await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
                    await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

                    // Capture viewport buffer
                    var image = _subViewport.GetTexture().GetImage();
                    string fileName = $"{dirPath}/{resNames[r]}_{modeNames[m]}_{seedNames[s]}.png";
                    
                    Error err = image.SavePng(fileName);
                    if (err == Error.Ok)
                    {
                        GD.Print($"[AUDIT] Saved visual screenshot: {fileName}");
                    }
                    else
                    {
                        GD.PrintErr($"[AUDIT] Failed to save screenshot: {fileName} (Error: {err})");
                    }
                }
            }
        }

        GD.Print("=== Visual Audit Pipeline Completed Successfully ===");
        GetTree().Quit();
    }

    private void ChangeSeedColor(Color seed)
    {
        M3ThemeManager.Instance.CurrentSeedColor = seed;
    }

    private void SetEmulatorResolution(Vector2 targetSize, string frameLabel, float scaleFactor)
    {
        _isAutoRes = false; // Disable auto adaptive resizing when manual preset is selected
        if (_emuViewportFrame == null || _subViewport == null) return;

        // Apply dynamic visual DPI scaling
        if (M3ThemeManager.Instance != null)
        {
            M3ThemeManager.Instance.ScaleFactor = scaleFactor;
        }

        // Disable container expansion so preset sizes are respected exactly
        _emuViewportFrame.SizeFlagsHorizontal = Control.SizeFlags.ShrinkCenter;
        _emuViewportFrame.SizeFlagsVertical = Control.SizeFlags.ShrinkCenter;

        // Animate the viewport resize using standard M3 motion curve
        var tween = CreateTween().SetParallel(true);
        tween.TweenProperty(_emuViewportFrame, "custom_minimum_size", targetSize, 0.25f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);

        // Set viewport size manually only if the parent container doesn't stretch it automatically
        var container = _subViewport.GetParent() as SubViewportContainer;
        if (container == null || !container.Stretch)
        {
            _subViewport.Size = new Vector2I((int)targetSize.X, (int)targetSize.Y);
        }

        // Explicitly update DemoContent size because SubViewport doesn't automatically propagate sizes to direct Control children
        var demoContent = _subViewport.GetNodeOrNull<Control>("DemoContent");
        if (demoContent != null)
        {
            demoContent.Size = targetSize;
        }
        
        GD.Print($"Emulating resolution: {frameLabel} ({targetSize.X}x{targetSize.Y}) with ScaleFactor: {scaleFactor}");
    }

    private async void SetEmulatorResolutionAuto()
    {
        _isAutoRes = true;

        // Clear manual overrides in theme manager so it adapts dynamically to physical density & scale
        M3ThemeManager.Instance?.ClearScaleOverride();

        // Enable container expansion so the ViewportFrame fills all available space in the MarginContainer
        _emuViewportFrame.SizeFlagsHorizontal = Control.SizeFlags.Fill | Control.SizeFlags.Expand;
        _emuViewportFrame.SizeFlagsVertical = Control.SizeFlags.Fill | Control.SizeFlags.Expand;

        // Reset custom_minimum_size so the layout system determines the actual size
        _emuViewportFrame.CustomMinimumSize = new Vector2(300, 200);

        // Wait for Godot layout reflow to settle
        await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
        await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

        UpdateAutoResolutionLayout();
    }

    private async void OnViewportSizeChanged()
    {
        if (_isAutoRes)
        {
            // Wait for Godot layout reflow to settle
            await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
            UpdateAutoResolutionLayout();
        }
    }

    private void UpdateAutoResolutionLayout()
    {
        if (_emuViewportFrame == null || _subViewport == null) return;

        // In auto mode, the MarginContainer parent stretches the ViewportFrame
        // to fill available space, so we just need to read the actual resulting size
        // and update the SubViewport to match.
        Vector2 actualSize = _emuViewportFrame.Size;

        if (actualSize.X < 1 || actualSize.Y < 1) return;

        var container = _subViewport.GetParent() as SubViewportContainer;
        if (container == null || !container.Stretch)
        {
            _subViewport.Size = new Vector2I((int)actualSize.X, (int)actualSize.Y);
        }

        // Propagate size changes to direct Control child inside SubViewport
        var demoContent = _subViewport.GetNodeOrNull<Control>("DemoContent");
        if (demoContent != null)
        {
            demoContent.Size = actualSize;
        }

        float currentScale = M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;
        GD.Print($"Auto Emulator adapting to resolution: {actualSize.X}x{actualSize.Y} with ScaleFactor: {currentScale}");
    }
}
