using GdUnit4;
using Godot;
using Material3.Components;
using Material3.Core;
using static GdUnit4.Assertions;

namespace Material3.Test;

/// <summary>
/// Comprehensive unit tests covering dynamic behaviors, state machines, and clamping
/// across the expanded Material 3 control collection.
/// </summary>
[TestSuite]
public class M3ControlsTest
{
    [TestCase]
    public void TestSwitchState()
    {
        var control = new M3Switch();
        control.Checked = false;
        AssertThat(control.Checked).IsFalse();

        control.Checked = true;
        AssertThat(control.Checked).IsTrue();
        control.Free();
    }

    [TestCase]
    public void TestCheckboxState()
    {
        var control = new M3Checkbox();
        control.Checked = false;
        AssertThat(control.Checked).IsFalse();

        control.Checked = true;
        AssertThat(control.Checked).IsTrue();
        control.Free();
    }

    [TestCase]
    public void TestSliderClamping()
    {
        var control = new M3Slider();
        control.MinValue = 0.0f;
        control.MaxValue = 100.0f;
        control.Step = 1.0f;

        // Verify direct assignment
        control.Value = 45.3f;
        AssertThat(control.Value).IsEqual(45.0f); // Steps to 45

        // Verify upper clamping bounds
        control.Value = 150.0f;
        AssertThat(control.Value).IsEqual(100.0f);

        // Verify lower clamping bounds
        control.Value = -50.0f;
        AssertThat(control.Value).IsEqual(0.0f);
        control.Free();
    }

    [TestCase]
    public void TestProgressIndicatorClamping()
    {
        var control = new M3ProgressIndicator();
        control.ProgressValue = 0.5f;
        AssertThat(control.ProgressValue).IsEqual(0.5f);

        // Verify bounds clamping
        control.ProgressValue = 1.5f;
        AssertThat(control.ProgressValue).IsEqual(1.0f);

        control.ProgressValue = -0.5f;
        AssertThat(control.ProgressValue).IsEqual(0.0f);
        control.Free();
    }

    [TestCase]
    public void TestTextFieldText()
    {
        var control = new M3TextField();
        control.Text = "Hello Godot";
        AssertThat(control.Text).IsEqual("Hello Godot");

        control.LabelText = "Username";
        AssertThat(control.LabelText).IsEqual("Username");
        control.Free();
    }

    [TestCase]
    public void TestTabBarSelection()
    {
        var control = new M3TabBar();
        
        // Tab index changes out of bounds should be ignored or clamped
        control.SelectedIndex = 1;
        AssertThat(control.SelectedIndex).IsEqual(1);

        control.SelectedIndex = 99; // Invalid index
        AssertThat(control.SelectedIndex).IsEqual(1); // Keeps previous
        control.Free();
    }
}
