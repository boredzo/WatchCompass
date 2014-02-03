#import "PRHCompassView.h"

#import <QuartzCore/QuartzCore.h>

@interface PRHCompassView ()

- (IBAction) toggleRotationOfEarth:(id)sender;

@end

static void countSinglePathElement(void *info, const CGPathElement *element) {
	NSUInteger *countPtr = info;
	if (element->type != kCGPathElementCloseSubpath)
		++*countPtr;
}
static NSUInteger PRHCountElementsOfPath(CGPathRef path) {
	NSUInteger count = 0;
	CGPathApply(path, &count, countSinglePathElement);
	return count;
}

@implementation PRHCompassView
{
	CALayer *_rootLayer;
	CALayer *_sunLayer;
	CALayer *_watchFaceLayer;
	CAShapeLayer *_hourHandLayer;
}

- (id) initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		_rootLayer = [CALayer new];
		_rootLayer.bounds = (NSRect){ NSZeroPoint, frame.size };
		_rootLayer.delegate = self;
		//_rootLayer.speed = 1800.0;
		self.layer = _rootLayer;
		self.wantsLayer = YES;

		_watchFaceLayer = [CALayer new];
		_watchFaceLayer.borderColor = CGColorGetConstantColor(kCGColorBlack); _watchFaceLayer.borderWidth = 1.0;
		NSImage *watchFaceImage = [NSImage imageNamed:@"WatchFace"];
		_watchFaceLayer.contents = watchFaceImage;
		_watchFaceLayer.bounds = (NSRect){ NSZeroPoint, watchFaceImage.size };
		[_rootLayer addSublayer:_watchFaceLayer];

		_hourHandLayer = [CAShapeLayer new];
		_hourHandLayer.borderColor = CGColorGetConstantColor(kCGColorBlack); _hourHandLayer.borderWidth = 1.0;
		CGMutablePathRef hourHandPath = CGPathCreateMutable();
		NSRect hourHandRect = { NSZeroPoint, { 4.0, 35.0 } };
		CGPathMoveToPoint(hourHandPath, /*transform*/ NULL, NSMidX(hourHandRect), NSMinY(hourHandRect) );
		CGPathAddLineToPoint(hourHandPath, /*transform*/ NULL, NSMidX(hourHandRect), NSMaxY(hourHandRect) );
		_hourHandLayer.path = hourHandPath;
		_hourHandLayer.strokeColor = CGColorGetConstantColor(kCGColorBlack);
		_hourHandLayer.lineCap = kCALineCapRound;
		_hourHandLayer.lineWidth = 4.0;
		_hourHandLayer.bounds = hourHandRect;
		_hourHandLayer.anchorPoint = (NSPoint){ 0.5, 1.0 };
		[_watchFaceLayer addSublayer:_hourHandLayer];

		_sunLayer = [CALayer new];
		_sunLayer.borderColor = CGColorGetConstantColor(kCGColorBlack); _sunLayer.borderWidth = 1.0;
		NSImage *sunImage = [NSImage imageNamed:@"Sun"];
		_sunLayer.contents = sunImage;
		NSSize sunSize = sunImage.size;
		_sunLayer.bounds = (NSRect){ NSZeroPoint, sunSize };
		[_rootLayer addSublayer:_sunLayer];

		NSString *key = @"position";
		CAKeyframeAnimation *sunPositionAnimation = [CAKeyframeAnimation animationWithKeyPath:key];
		NSRect sunPathRect = frame;
		sunPathRect = NSInsetRect(sunPathRect, sunSize.width / 2.0, sunSize.height / 2.0);
		sunPathRect.origin.y -= sunPathRect.size.height;
		sunPathRect.size.height *= 2.0;
		CGPathRef sunPath = CGPathCreateWithEllipseInRect(sunPathRect, /*transform*/ NULL);
		sunPositionAnimation.path = sunPath;
		NSUInteger numStops = PRHCountElementsOfPath(sunPath);
		CGPathRelease(sunPath);
		NSMutableArray *stopTimes = [NSMutableArray arrayWithCapacity:numStops];
		--numStops;
		for (NSUInteger i = 0; i <= numStops; ++i) {
			[stopTimes addObject:@(i / (float)numStops)];
		}
		sunPositionAnimation.keyTimes = stopTimes;
		sunPositionAnimation.rotationMode = kCAAnimationRotateAuto;
		sunPositionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		//sunPositionAnimation.duration = 24.0 * 3600.0;
		static const NSTimeInterval dayLength = 5.0;
		sunPositionAnimation.duration = dayLength; //TEMP
		sunPositionAnimation.repeatCount = HUGE_VALF;
		[_sunLayer addAnimation:sunPositionAnimation forKey:key];

		CAShapeLayer *sunPathLayer = [CAShapeLayer new];
		sunPathLayer.bounds = sunPathRect;
		NSRect compassBounds = _rootLayer.bounds;
		NSPoint bottomMiddle = { NSMidX(compassBounds), NSMinY(compassBounds) + 1.0 };
		sunPathLayer.position = bottomMiddle;
		sunPathLayer.path = sunPath;
		sunPathLayer.strokeColor = CGColorGetConstantColor(kCGColorBlack); sunPathLayer.lineWidth = 1.0;
		sunPathLayer.fillColor = NULL;
		[_rootLayer addSublayer:sunPathLayer];

		key = @"transform";
		NSString *keyPath = @"transform.rotation.z";
		CABasicAnimation *handRotationAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
		handRotationAnimation.fromValue = @(M_PI * 2.0);
		handRotationAnimation.toValue = @0.0;
		handRotationAnimation.cumulative = YES;
		handRotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		//handRotationAnimation.duration = 12.0 * 3600.0;
		handRotationAnimation.duration = dayLength / 2.0; //TEMP
		handRotationAnimation.repeatCount = HUGE_VALF;
		[_hourHandLayer addAnimation:handRotationAnimation forKey:key];

		//Shrink down the clock so the whole thing is visible.
		[_watchFaceLayer setValue:@+50.0 forKeyPath:@"transform.translation.y"];
		[_watchFaceLayer setValue:@0.5 forKeyPath:@"transform.scale.x"];
		[_watchFaceLayer setValue:@0.5 forKeyPath:@"transform.scale.y"];
		[_watchFaceLayer setValue:@(M_PI / 2.0) forKeyPath:keyPath];
		/*TBD
		CABasicAnimation *watchFaceRotationAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
		watchFaceRotationAnimation.toValue = @(M_PI * 2.0);
		watchFaceRotationAnimation.cumulative = YES;
		watchFaceRotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		watchFaceRotationAnimation.duration = 12.0 * 3600.0;
		watchFaceRotationAnimation.repeatCount = HUGE_VALF;
		[_watchFaceLayer addAnimation:watchFaceRotationAnimation forKey:key];
		*/
	}

	return self;
}

- (void) viewDidChangeBackingProperties {
	CGFloat scaleFactor = self.window.backingScaleFactor;
	_rootLayer.contentsScale = scaleFactor;
	_sunLayer.contentsScale = scaleFactor;
	_watchFaceLayer.contentsScale = scaleFactor;
}

//Lifted from https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreAnimation_guide/AdvancedAnimationTricks/AdvancedAnimationTricks.html#//apple_ref/doc/uid/TP40004514-CH8-SW15 .
- (void) pauseLayer:(CALayer *)layer {
	CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
	layer.speed = 0.0;
	layer.timeOffset = pausedTime;
}
- (void) resumeLayer:(CALayer *)layer {
	CFTimeInterval pausedTime = [layer timeOffset];
	layer.speed = 1.0;
	layer.timeOffset = 0.0;
	layer.beginTime = 0.0;
	CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
	layer.beginTime = timeSincePause;
}

- (IBAction) toggleRotationOfEarth:(id)sender {
	CALayer *layer = _rootLayer;
	if (layer.speed != 0.0) {
		[self pauseLayer:layer];
	} else {
		[self resumeLayer:layer];
	}
}

- (void) layoutSublayersOfLayer:(CALayer *)layer {
	if (layer == _rootLayer) {
		NSRect compassBounds = layer.bounds;
		_watchFaceLayer.position = (NSPoint){ NSMidX(compassBounds), NSMinY(compassBounds) };
		CGRect watchFaceBounds = _watchFaceLayer.bounds;
		_hourHandLayer.position = (NSPoint){ NSMidX(watchFaceBounds), NSMidY(watchFaceBounds) };
		//Sun is positioned by the animation.
	}
}

@end
