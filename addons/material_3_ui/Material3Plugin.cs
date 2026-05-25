#if TOOLS
using Godot;

[Tool]
public partial class Material3Plugin : EditorPlugin
{
    // The exact path to your new manager script
    private const string AutoloadName = "MaterialThemeManager";
    private const string AutoloadPath = "res://addons/material_3_ui/MaterialThemeManager.cs";

    public override void _EnterTree()
    {
        // Automatically add the autoload when the plugin is enabled
        AddAutoloadSingleton(AutoloadName, AutoloadPath);
        GD.Print("Material 3 UI Plugin Enabled.");
    }

    public override void _ExitTree()
    {
        // Clean up the user's project settings when disabled
        RemoveAutoloadSingleton(AutoloadName);
        GD.Print("Material 3 UI Plugin Disabled.");
    }
}
#endif
