#import "PRHWatchCompassWindowController.h"
#import "PRHCompassView.h"

@interface PRHWatchCompassWindowController ()

@property(weak) IBOutlet PRHCompassView *compassView;

@end

@implementation PRHWatchCompassWindowController

- (instancetype) initWithWindow:(NSWindow *)window {
	self = [super initWithWindow:window];
	if (self) {
	}

	return self;
}

- (instancetype) init {
	return [self initWithWindowNibName:NSStringFromClass([self class])];
}

- (void) windowDidLoad {
	[super windowDidLoad];

	self.compassView.hour = 12.0;
}

@end
