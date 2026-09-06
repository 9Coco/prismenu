import QtQuick
import QtTest
import "../../package/contents/ui" as Menu

TestCase {
    name: "SearchProviderLifecycle"

    Menu.SearchNativeProviders {
        id: providers
        liveUpdates: false
    }
    SignalSpy { id: recentSpy; target: providers; signalName: "recentFilesUpdated" }
    SignalSpy { id: windowSpy; target: providers; signalName: "openWindowsUpdated" }

    function init() {
        providers.liveUpdates = false;
        wait(0);
        recentSpy.clear();
        windowSpy.clear();
    }

    function test_homeDoesNotStartSearchProviders() {
        providers.liveUpdates = true;
        // Model changes must not opt the launcher into search work.
        providers.queueRecentFilesRebuild();
        providers.queueOpenWindowsRebuild();
        wait(30);
        compare(recentSpy.count, 0);
        compare(windowSpy.count, 0);
        verify(!providers.recentFilesActive);
        verify(!providers.openWindowsActive);
    }

    function test_recentPageDoesNotStartWindowProvider() {
        providers.liveUpdates = true;
        providers.requestRecentFiles();
        tryVerify(function () { return recentSpy.count > 0; });
        compare(windowSpy.count, 0);
        verify(providers.recentFilesActive);
        verify(!providers.openWindowsActive);
    }

    function test_windowSearchDoesNotStartRecentProvider() {
        providers.liveUpdates = true;
        providers.requestOpenWindows();
        tryVerify(function () { return windowSpy.count > 0; });
        compare(recentSpy.count, 0);
        verify(!providers.recentFilesActive);
    }

    function test_closeCancelsQueuedRefresh() {
        providers.liveUpdates = true;
        providers.requestRecentFiles();
        providers.requestOpenWindows();
        providers.liveUpdates = false;
        wait(30);
        compare(recentSpy.count, 0);
        compare(windowSpy.count, 0);
        verify(!providers.recentFilesRequested);
        verify(!providers.openWindowsRequested);
    }

    function test_requestWhileClosedDoesNotWakeProviders() {
        providers.requestRecentFiles();
        providers.requestOpenWindows();
        providers.liveUpdates = true;
        wait(30);
        compare(recentSpy.count, 0);
        compare(windowSpy.count, 0);
    }

    function test_reopenRefreshesPreviouslyRequestedSources() {
        providers.liveUpdates = true;
        providers.refresh();
        tryVerify(function () { return recentSpy.count > 0 && windowSpy.count > 0; });
        providers.liveUpdates = false;
        wait(0);
        recentSpy.clear();
        windowSpy.clear();
        providers.liveUpdates = true;
        wait(30);
        compare(recentSpy.count, 0);
        compare(windowSpy.count, 0);
        providers.refresh();
        tryVerify(function () { return recentSpy.count > 0 && windowSpy.count > 0; });
    }
}
