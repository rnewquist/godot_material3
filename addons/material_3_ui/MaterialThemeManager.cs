using Godot;

[Tool]
public partial class MaterialThemeManager : Node
{
    // Define a signal that components can listen to
    [Signal]
    public delegate void ThemeChangedEventHandler();

    // Example Token: Primary Color (Defaulting to M3 Baseline Purple)
    private Color _primary = new Color("#6750A4");
    public Color Primary
    {
        get => _primary;
        set 
        { 
            _primary = value; 
            EmitSignal(SignalName.ThemeChanged); 
        }
    }

    // Example Token: On-Primary (Text/Icon color on top of primary)
    private Color _onPrimary = new Color("#FFFFFF");
    public Color OnPrimary
    {
        get => _onPrimary;
        set 
        { 
            _onPrimary = value; 
            EmitSignal(SignalName.ThemeChanged); 
        }
    }

    // You can expand this to include Secondary, Tertiary, Error, Surface, etc.
}
