#import "MJLinkTextField.h"

// Thanks to http://toomasvahter.wordpress.com/2012/12/25/embedding-hyperlinks-in-nstextfield/ for some key ideas

@interface MJLinkTextField ()
@property NSMutableArray* cachedLinks;
@end

@implementation MJLinkTextField

- (void) addLink:(NSString*)link inRange:(NSRange)r {
    NSString* text = [self stringValue];
    NSMutableAttributedString* mastr = [[NSMutableAttributedString alloc] initWithString: text];
    
    [mastr beginEditing];
    [mastr addAttribute:NSLinkAttributeName value:[NSURL URLWithString: link] range:r];
    [mastr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:r];
    [mastr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:r];
    [mastr endEditing];
    
    [self setAttributedStringValue: mastr];
}

static NSTextView* MJTextViewForField(NSTextField* self) {
    NSMutableAttributedString* mastr = [[self attributedStringValue] mutableCopy];
    NSFont* font = [mastr attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    
    if (!font) {
        [mastr addAttribute:NSFontAttributeName
                      value:[self font]
                      range:NSMakeRange(0, [mastr length])];
    }
    
    NSTextView* tv = [[NSTextView alloc] initWithFrame:[[self cell] titleRectForBounds:[self bounds]]];
    [[tv textStorage] setAttributedString: mastr];
    
    return tv;
}

- (void) cacheLinks {
    self.cachedLinks = [NSMutableArray array];
    
    NSRange r = NSMakeRange(0, [[self attributedStringValue] length]);
    NSTextView* tv = MJTextViewForField(self);
    [[self attributedStringValue]
     enumerateAttribute:NSLinkAttributeName
     inRange:r
     options:0
     usingBlock:^(NSURL* value, NSRange range, BOOL *stop) {
         if (!value)
             return;
         
         NSUInteger count;
         NSRectArray array = [[tv layoutManager] rectArrayForCharacterRange:range
                                               withinSelectedCharacterRange:range
                                                            inTextContainer:[tv textContainer]
                                                                  rectCount:&count];
         
         for (NSUInteger i = 0; i < count; i++) {
             [self.cachedLinks addObject: @{@"rect": [NSValue valueWithRect:array[i]],
                                            @"url": value}];
         }
     }];
}

- (void) mouseUp:(NSEvent *)theEvent {
    NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    p.y--; // docs say it has base of 1 for some reason, not 0
    
    for (NSDictionary* link in self.cachedLinks) {
        NSValue* rectValue = [link objectForKey:@"rect"];
        
        if (NSPointInRect(p, [rectValue rectValue])) {
            NSURL* url = [link objectForKey:@"url"];
            [[NSWorkspace sharedWorkspace] openURL:url];
            return;
        }
    }
    
    [super mouseUp:theEvent];
}

- (void) resetCursorRects {
    [super resetCursorRects];
    [self cacheLinks];
    
    for (NSDictionary* link in self.cachedLinks) {
        NSValue* rectValue = [link objectForKey:@"rect"];
        [self addCursorRect:[rectValue rectValue] cursor:[NSCursor pointingHandCursor]];
    }
}

@end
