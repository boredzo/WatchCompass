#import "PRHAppDelegate.h"
#import "PRHWatchCompassWindowController.h"

@implementation PRHAppDelegate
{
	PRHWatchCompassWindowController *_wc;
}

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	_wc = [PRHWatchCompassWindowController new];
	[_wc showWindow:nil];
}

- (void) applicationWillTerminate:(NSNotification *)notification {
	[_wc close];
	_wc = nil;
}

@end
