using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Media.Imaging;
using Avalonia.Platform;
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace TestApp;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    public void ClickHandler(object sender, RoutedEventArgs args)
    {
        if (sender is Button clickedButton)
        {
            switch (clickedButton.Name)
            {
                case "Login":
                    if ((Username.Text == "Migratedwolf") && (Password.Text == "Echo123e#"))
                    {
                        clickedButton.Content = "Logout";
                        LoginFailed.IsVisible = false;

                        var secondWindow = new SecondWindow();
                        secondWindow.Show();

                    // Optionally hide or close MainWindow
                    this.Hide(); // or this.Close();
                    }
                    else
                    {
                        LoginFailed.IsVisible = true;
                    }
                    break;
                case "Signup":
                    if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                    {
                        // Use cmd to launch the default browser
                        Process.Start(new ProcessStartInfo("cmd", $"/c start https://www.fredericton.ca/en")
                        {
                            CreateNoWindow = true
                        });
                    }
                    else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                    {
                        // Use xdg-open to launch default browser
                        Process.Start("xdg-open", "https://www.fredericton.ca/en");
                    }
                    break;
            }

        }
    }
}