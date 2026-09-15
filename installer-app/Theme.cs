namespace QolSeriesInstaller;

// One palette definition for the whole product: the app window, the setup window and any
// dialog either of them puts up.
internal sealed record Palette(string Key, string Name, string Note, bool Dark, Color Window, Color Side, Color Base, Color Card, Color CardHover, Color Line, Color LineHover, Color Caption, Color Muted, Color Sub, Color Ink, Color Accent, Color AccentHover, Color AccentText, Color Secondary, Color SecondaryHover, Color Good);

internal static class Palettes
{
    internal static Palette Default => All[0];
    internal static Palette ByKey(string? key) => All.FirstOrDefault(t => t.Key == key) ?? Default;

    internal static readonly Palette[] All =
    [
        new("classic", "Classic Dark", "A plain, classic dark grey look.", true,
            Color.FromArgb(20, 21, 24), Color.FromArgb(21, 22, 26), Color.FromArgb(26, 27, 32), Color.FromArgb(35, 37, 43), Color.FromArgb(41, 44, 51), Color.FromArgb(35, 37, 43), Color.FromArgb(58, 62, 71),
            Color.FromArgb(122, 128, 139), Color.FromArgb(154, 160, 172), Color.FromArgb(178, 184, 196), Color.FromArgb(232, 234, 238), Color.FromArgb(79, 156, 249), Color.FromArgb(108, 176, 255), Color.FromArgb(12, 22, 36), Color.FromArgb(47, 50, 58), Color.FromArgb(57, 61, 70), Color.FromArgb(109, 205, 138)),
        new("oled", "OLED Black", "True black for OLED screens.", true,
            Color.FromArgb(0, 0, 0), Color.FromArgb(0, 0, 0), Color.FromArgb(4, 4, 6), Color.FromArgb(12, 12, 15), Color.FromArgb(18, 18, 22), Color.FromArgb(12, 12, 15), Color.FromArgb(30, 30, 36),
            Color.FromArgb(120, 126, 138), Color.FromArgb(150, 156, 168), Color.FromArgb(176, 182, 194), Color.FromArgb(233, 235, 239), Color.FromArgb(45, 212, 191), Color.FromArgb(94, 234, 212), Color.FromArgb(4, 26, 24), Color.FromArgb(24, 24, 29), Color.FromArgb(34, 34, 40), Color.FromArgb(110, 231, 159)),
        new("mocha", "Catppuccin Mocha", "The warm, pastel dark theme.", true,
            Color.FromArgb(17, 17, 27), Color.FromArgb(24, 24, 37), Color.FromArgb(30, 30, 46), Color.FromArgb(49, 50, 68), Color.FromArgb(58, 60, 82), Color.FromArgb(49, 50, 68), Color.FromArgb(69, 71, 90),
            Color.FromArgb(108, 112, 134), Color.FromArgb(147, 153, 178), Color.FromArgb(166, 173, 200), Color.FromArgb(205, 214, 244), Color.FromArgb(148, 226, 213), Color.FromArgb(137, 220, 235), Color.FromArgb(17, 17, 27), Color.FromArgb(69, 71, 90), Color.FromArgb(88, 91, 112), Color.FromArgb(166, 227, 161)),
        new("macchiato", "Catppuccin Macchiato", "A slightly brighter pastel dark.", true,
            Color.FromArgb(24, 25, 38), Color.FromArgb(30, 32, 48), Color.FromArgb(36, 39, 58), Color.FromArgb(54, 58, 79), Color.FromArgb(64, 68, 92), Color.FromArgb(54, 58, 79), Color.FromArgb(73, 78, 102),
            Color.FromArgb(110, 115, 141), Color.FromArgb(149, 154, 183), Color.FromArgb(165, 173, 203), Color.FromArgb(202, 211, 245), Color.FromArgb(139, 213, 202), Color.FromArgb(125, 196, 228), Color.FromArgb(24, 25, 38), Color.FromArgb(73, 78, 102), Color.FromArgb(91, 96, 120), Color.FromArgb(166, 218, 149)),
        new("frappe", "Catppuccin Frappe", "A muted, low-contrast pastel dark.", true,
            Color.FromArgb(35, 38, 52), Color.FromArgb(41, 44, 60), Color.FromArgb(48, 52, 70), Color.FromArgb(65, 69, 89), Color.FromArgb(76, 80, 102), Color.FromArgb(65, 69, 89), Color.FromArgb(85, 90, 112),
            Color.FromArgb(115, 121, 148), Color.FromArgb(156, 160, 188), Color.FromArgb(173, 179, 206), Color.FromArgb(198, 208, 245), Color.FromArgb(129, 200, 190), Color.FromArgb(133, 193, 220), Color.FromArgb(35, 38, 52), Color.FromArgb(85, 90, 112), Color.FromArgb(98, 104, 128), Color.FromArgb(166, 209, 137)),
        new("latte", "Catppuccin Latte", "A soft light theme.", false,
            Color.FromArgb(220, 224, 232), Color.FromArgb(230, 233, 239), Color.FromArgb(239, 241, 245), Color.FromArgb(255, 255, 255), Color.FromArgb(244, 246, 250), Color.FromArgb(188, 192, 204), Color.FromArgb(172, 176, 190),
            Color.FromArgb(140, 143, 160), Color.FromArgb(124, 127, 147), Color.FromArgb(92, 95, 119), Color.FromArgb(76, 79, 105), Color.FromArgb(23, 146, 153), Color.FromArgb(32, 159, 181), Color.FromArgb(255, 255, 255), Color.FromArgb(220, 224, 232), Color.FromArgb(204, 208, 218), Color.FromArgb(64, 160, 43)),
        new("t3-chat", "T3 Chat", "T3 Code's T3 Chat palette.", true,
            Color.FromArgb(25, 20, 30), Color.FromArgb(25, 20, 30), Color.FromArgb(31, 26, 36), Color.FromArgb(47, 43, 52), Color.FromArgb(55, 50, 60), Color.FromArgb(59, 55, 64), Color.FromArgb(72, 68, 77),
            Color.FromArgb(129, 126, 133), Color.FromArgb(166, 164, 169), Color.FromArgb(201, 199, 204), Color.FromArgb(249, 248, 251), Color.FromArgb(163, 0, 76), Color.FromArgb(180, 46, 108), Color.FromArgb(255, 255, 255), Color.FromArgb(62, 57, 66), Color.FromArgb(72, 68, 77), Color.FromArgb(118, 207, 138)),
        new("t3-chat-light", "T3 Chat Light", "T3 Code's light palette.", false,
            Color.FromArgb(243, 237, 243), Color.FromArgb(243, 237, 243), Color.FromArgb(253, 247, 253), Color.FromArgb(255, 255, 255), Color.FromArgb(254, 251, 254), Color.FromArgb(225, 211, 226), Color.FromArgb(208, 189, 209),
            Color.FromArgb(175, 147, 177), Color.FromArgb(146, 109, 148), Color.FromArgb(118, 73, 121), Color.FromArgb(80, 24, 84), Color.FromArgb(219, 39, 119), Color.FromArgb(180, 32, 98), Color.FromArgb(255, 255, 255), Color.FromArgb(241, 231, 241), Color.FromArgb(232, 220, 233), Color.FromArgb(41, 134, 70)),
        new("grove", "T3 Grove", "T3 Code's green palette.", true,
            Color.FromArgb(21, 34, 27), Color.FromArgb(21, 34, 27), Color.FromArgb(27, 40, 33), Color.FromArgb(44, 56, 50), Color.FromArgb(52, 63, 57), Color.FromArgb(57, 67, 62), Color.FromArgb(70, 80, 75),
            Color.FromArgb(130, 134, 133), Color.FromArgb(168, 170, 171), Color.FromArgb(205, 204, 206), Color.FromArgb(255, 250, 255), Color.FromArgb(105, 214, 154), Color.FromArgb(132, 221, 172), Color.FromArgb(10, 12, 14), Color.FromArgb(59, 69, 64), Color.FromArgb(70, 80, 75), Color.FromArgb(118, 207, 138)),
        new("ocean", "T3 Ocean", "T3 Code's blue palette.", true,
            Color.FromArgb(17, 27, 37), Color.FromArgb(17, 27, 37), Color.FromArgb(23, 33, 43), Color.FromArgb(40, 49, 59), Color.FromArgb(49, 57, 66), Color.FromArgb(53, 61, 71), Color.FromArgb(67, 74, 83),
            Color.FromArgb(127, 131, 138), Color.FromArgb(167, 168, 174), Color.FromArgb(204, 202, 208), Color.FromArgb(255, 250, 255), Color.FromArgb(112, 185, 238), Color.FromArgb(138, 198, 241), Color.FromArgb(10, 12, 14), Color.FromArgb(55, 63, 73), Color.FromArgb(67, 74, 83), Color.FromArgb(118, 207, 138)),
        new("ember", "T3 Ember", "T3 Code's warm palette.", true,
            Color.FromArgb(35, 24, 20), Color.FromArgb(35, 24, 20), Color.FromArgb(41, 30, 26), Color.FromArgb(57, 46, 43), Color.FromArgb(65, 54, 51), Color.FromArgb(69, 59, 56), Color.FromArgb(82, 72, 70),
            Color.FromArgb(137, 129, 129), Color.FromArgb(174, 166, 168), Color.FromArgb(208, 202, 205), Color.FromArgb(255, 250, 255), Color.FromArgb(240, 154, 100), Color.FromArgb(243, 172, 128), Color.FromArgb(10, 12, 14), Color.FromArgb(71, 61, 58), Color.FromArgb(82, 72, 70), Color.FromArgb(118, 207, 138)),
        new("iris", "T3 Iris", "T3 Code's purple palette.", true,
            Color.FromArgb(23, 19, 35), Color.FromArgb(23, 19, 35), Color.FromArgb(29, 25, 41), Color.FromArgb(46, 42, 57), Color.FromArgb(54, 50, 65), Color.FromArgb(58, 54, 69), Color.FromArgb(72, 68, 82),
            Color.FromArgb(131, 126, 137), Color.FromArgb(169, 164, 174), Color.FromArgb(205, 200, 208), Color.FromArgb(255, 250, 255), Color.FromArgb(157, 125, 242), Color.FromArgb(175, 148, 244), Color.FromArgb(10, 12, 14), Color.FromArgb(61, 56, 71), Color.FromArgb(72, 68, 82), Color.FromArgb(118, 207, 138))
    ];
}
