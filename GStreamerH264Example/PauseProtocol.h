//
//  PauseProtocol.h
//  GstreamerLiveStream
//
//  Created by Tord Wessman on 21/08/15.
//  Copyright (c) 2015 Axel IT AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PauseProtocol

@required
- (void) reset;

@end
