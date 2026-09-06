import QtQuick
import QtTest
import "../../package/contents/ui/components" as Components

TestCase {
    name: "BundledIcon"
    when: windowShown
    visible: true
    width: 120
    height: 120

    Components.ResolvedIcon {
        id: icon
        width: 48
        height: 48
        animated: false
    }

    function init() {
        icon.width = 48;
        icon.height = 48;
        icon.preferSymbolic = true;
        icon.tintColor = "#ff0000";
        icon.iconName = "prismenu-cat-tools-build";
    }

    function pixelsMatching(image, predicate) {
        let count = 0;
        for (let y = 0; y < image.height; ++y) {
            for (let x = 0; x < image.width; ++x) {
                if (image.alpha(x, y) > 200 && predicate(image.pixel(x, y)))
                    count++;
            }
        }
        return count;
    }

    function renderedImage() {
        tryCompare(icon, "valid", true);
        waitForRendering(icon);
        wait(30);
        return grabImage(icon);
    }

    function test_categoryMaskRetints() {
        // Kirigami applies mask colors in its scene-graph shader. The Qt
        // software renderer also leaves the original URL-backed masks black.
        if (icon.GraphicsInfo.api === GraphicsInfo.Software)
            skip("Kirigami mask tinting requires the RHI renderer");
        verify(pixelsMatching(renderedImage(), c => c.r > 0.8 && c.g < 0.2 && c.b < 0.2) > 50);
        icon.tintColor = "#0000ff";
        verify(pixelsMatching(renderedImage(), c => c.b > 0.8 && c.r < 0.2 && c.g < 0.2) > 50);
    }

    function test_sourceAndSizeChanges() {
        const before = renderedImage();
        icon.iconName = "prismenu-cat-games-esports";
        const after = renderedImage();
        verify(!before.equals(after));
        const smallPixels = pixelsMatching(after, c => true);
        icon.width = 96;
        icon.height = 96;
        const large = renderedImage();
        compare(large.width, after.width * 2);
        verify(smallPixels > 50);
        verify(pixelsMatching(large, c => true) > smallPixels * 2);
    }

    function test_colorPresetKeepsOriginalColors() {
        icon.iconName = "distro-ubuntu";
        icon.preferSymbolic = false;
        icon.tintColor = "#0000ff";
        verify(pixelsMatching(renderedImage(), c => c.r > 0.6 && c.b < 0.4) > 50);
    }
}
