//
//  HXWRunloopTask.m
//  UITableView加载高清图卡顿NSRunloop解决方案
//
//  Created by BTI-HXW on 2019/6/5.
//  Copyright © 2019 BTI-HXW. All rights reserved.
//

#import "HXWRunloopTask.h"
#define MAXTASKS 18
@interface HXWRunloopTask ()
/**
 任务
 */
@property (nonatomic, strong) NSMutableArray<RunloopTask> *tasks;
/**
 timer，唤醒runloop
 */
@property (nonatomic, strong) NSTimer *taskTimer;

@end
@implementation HXWRunloopTask
-(instancetype)init{
    if (self = [super init]) {
        [[NSRunLoop currentRunLoop] addTimer:self.taskTimer forMode:NSDefaultRunLoopMode];
        [self addObserver];
    }
    return self;
}


-(void)dealloc{
    [self.taskTimer invalidate];
    self.taskTimer = nil;
}

- (NSMutableArray<RunloopTask> *)tasks{
    if (!_tasks) {
        _tasks = [NSMutableArray new];
    }
    return _tasks;
}
///保持runloop一直运转
-(NSTimer *)taskTimer{
    if (!_taskTimer) {
        _taskTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 repeats:YES block:^(NSTimer * _Nonnull timer) {
            
        }];
        
    }
    return _taskTimer;
}
///添加到任务队列中
-(void)addTask:(RunloopTask)task{
    [self.tasks addObject:task];
    if (self.tasks.count > MAXTASKS) {
        [self.tasks removeObjectAtIndex:0];
    }
}
#pragma mark 向runloop中注册observer
- (void)addObserver{
    //拿到当前的Runloop
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    
    //定义一个观察者,static内存中只存在一个
    static CFRunLoopObserverRef obverser;
    //创建一个观察者
    obverser = CFRunLoopObserverCreate(NULL, kCFRunLoopAfterWaiting, YES, 0, &callBack, &context);
    //添加观察者！！！默认模式下，滑动的时候不处理渲染任务
    CFRunLoopAddObserver(runloop, obverser, kCFRunLoopDefaultMode);
    
    //release
    CFRelease(obverser);
}
///runloop即将休眠的observer回调
void callBack (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    HXWRunloopTask *runloopTask = (__bridge HXWRunloopTask*)info;
    if(runloopTask.tasks.count==0){
        return;
    }
    ///从任务队列中去任务执行
    RunloopTask task = runloopTask.tasks.firstObject;
    task();
    [runloopTask.tasks removeObjectAtIndex:0];
}
@end
