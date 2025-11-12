Incident Identifier: 50B594D7-9736-4B57-AB88-45AC153CB635
Distributor ID:      com.apple.TestFlight
Hardware Model:      iPhone14,8
Process:             IKO [8020]
Path:                /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/IKO
Identifier:          pl.pkobp.iko
Version:             3.177.29 (3.177.29.56620)
AppStoreTools:       17B54
AppVariant:          1:iPhone14,8:26
Beta:                YES
Code Type:           ARM-64 (Native)
Role:                Foreground
Parent Process:      launchd [1]
Coalition:           pl.pkobp.iko [3055]

Date/Time:           2025-11-07 18:58:05.3873 +0100
Launch Time:         2025-11-07 18:58:04.7637 +0100
OS Version:          iPhone OS 26.1 (23B85)
Release Type:        User
Baseband Version:    4.10.01
Report Version:      104

Exception Type:  EXC_BREAKPOINT (SIGTRAP)
Exception Codes: 0x0000000000000001, 0x0000000101ae8b90
Termination Reason: SIGNAL 5 Trace/BPT trap: 5
Terminating Process: exc handler [8020]

Triggered by Thread:  0


Thread 0 name:
Thread 0 Crashed:
0   IKO                           	0x0000000101ae8b90 0x100e98000 + 12913552
1   Dependencies                  	0x0000000106dcb858 0x106dc4000 + 30808
2   Dependencies                  	0x0000000106dcd3b4 0x106dc4000 + 37812
3   libswift_Concurrency.dylib    	0x00000001993f3690 TaskLocal.withValue<A>(_:operation:file:line:) + 232 (TaskLocal.swift:305)
4   IssueReporting                	0x0000000107b95f94 0x107b84000 + 73620
5   Dependencies                  	0x0000000106dca2c8 0x106dc4000 + 25288
6   Dependencies                  	0x0000000106dc9508 0x106dc4000 + 21768
7   IKO                           	0x0000000101ae8ca0 0x100e98000 + 12913824
8   libswiftCore.dylib            	0x000000019824c104 KeyPath._projectReadOnly(from:) + 632 (KeyPath.swift:347)
9   libswiftCore.dylib            	0x0000000198251a70 swift_getAtKeyPath + 24 (KeyPath.swift:2234)
10  Dependencies                  	0x0000000106dc84d4 0x106dc4000 + 17620
11  Dependencies                  	0x0000000106dc89a8 0x106dc4000 + 18856
12  libswift_Concurrency.dylib    	0x00000001993f3690 TaskLocal.withValue<A>(_:operation:file:line:) + 232 (TaskLocal.swift:305)
13  Dependencies                  	0x0000000106dc8210 0x106dc4000 + 16912
14  IKO                           	0x0000000101ae92b8 0x100e98000 + 12915384
15  IKO                           	0x0000000101ac47e8 0x100e98000 + 12765160
16  IKO                           	0x0000000101ac4570 0x100e98000 + 12764528
17  Combine                       	0x00000001b1d9dd78 Subscribers.Sink.receive(_:) + 92 (Sink.swift:128)
18  Combine                       	0x00000001b1d9dd0c protocol witness for Subscriber.receive(_:) in conformance Subscribers.Sink<A, B> + 24 (<compiler-generated>:0)
19  Combine                       	0x00000001b1da7204 closure #1 in Publishers.ReceiveOn.Inner.receive(_:) + 284 (ReceiveOn.swift:169)
20  libswiftDispatch.dylib        	0x00000001ab23a410 thunk for @escaping @callee_guaranteed () -> () + 36
21  libdispatch.dylib             	0x00000001d3360adc _dispatch_call_block_and_release + 32 (init.c:1575)
22  libdispatch.dylib             	0x00000001d337a7ec _dispatch_client_callout + 16 (client_callout.mm:85)
23  libdispatch.dylib             	0x00000001d3397b24 _dispatch_main_queue_drain.cold.5 + 812 (queue.c:8181)
24  libdispatch.dylib             	0x00000001d336fec8 _dispatch_main_queue_drain + 180 (queue.c:8162)
25  libdispatch.dylib             	0x00000001d336fe04 _dispatch_main_queue_callback_4CF + 44 (queue.c:8341)
26  CoreFoundation                	0x000000019af6c2c8 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 16 (CFRunLoop.c:1820)
27  CoreFoundation                	0x000000019af1fb3c __CFRunLoopRun + 1944 (CFRunLoop.c:3177)
28  CoreFoundation                	0x000000019af1ea6c _CFRunLoopRunSpecificWithOptions + 532 (CFRunLoop.c:3462)
29  GraphicsServices              	0x000000023bb40498 GSEventRunModal + 120 (GSEvent.c:2049)
30  UIKitCore                     	0x00000001a08e2ba4 0x1a0845000 + 646052
31  UIKitCore                     	0x00000001a088ba78 0x1a0845000 + 289400
32  IKO                           	0x00000001013df284 0x100e98000 + 5534340
33  dyld                          	0x0000000197f36e28 start + 7116 (dyldMain.cpp:1477)

Thread 1:

Thread 2:

Thread 3:

Thread 4:

Thread 5:

Thread 6:

Thread 7 name:
Thread 7:
0   libsystem_kernel.dylib        	0x000000024485bcd4 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	0x000000024485f2f8 mach_msg2_internal + 76 (mach_msg.c:201)
2   libsystem_kernel.dylib        	0x000000024485f214 mach_msg_overwrite + 428 (mach_msg.c:0)
3   libsystem_kernel.dylib        	0x000000024485f05c mach_msg + 24 (mach_msg.c:323)
4   CoreFoundation                	0x000000019af48868 __CFRunLoopServiceMachPort + 160 (CFRunLoop.c:2650)
5   CoreFoundation                	0x000000019af1f848 __CFRunLoopRun + 1188 (CFRunLoop.c:3035)
6   CoreFoundation                	0x000000019af1ea6c _CFRunLoopRunSpecificWithOptions + 532 (CFRunLoop.c:3462)
7   Foundation                    	0x0000000198f1ad60 -[NSRunLoop(NSRunLoop) runMode:beforeDate:] + 212 (NSRunLoop.m:375)
8   Foundation                    	0x0000000198f1af38 -[NSRunLoop(NSRunLoop) runUntilDate:] + 64 (NSRunLoop.m:422)
9   UIKitCore                     	0x00000001a08b7cac 0x1a0845000 + 470188
10  Foundation                    	0x00000001985da21c __NSThread__start__ + 732 (NSThread.m:997)
11  libsystem_pthread.dylib       	0x00000001f6f6d44c _pthread_start + 136 (pthread.c:931)
12  libsystem_pthread.dylib       	0x00000001f6f698cc thread_start + 8


Thread 0 crashed with ARM Thread State (64-bit):
    x0: 0x000000016ef65270   x1: 0x0000000000000001   x2: 0x0000000205236930   x3: 0x000000016ef65338
    x4: 0x000000010d064500   x5: 0x0000000000000017   x6: 0x0000000000000000   x7: 0x0000000000000000
    x8: 0x0000000000000000   x9: 0x0000000000000000  x10: 0x0000000000000003  x11: 0x0000010000000000
   x12: 0x00000000fffffffd  x13: 0x0000000000000000  x14: 0x0000000000000000  x15: 0x0000000000000000
   x16: 0x0000000206cc8c98  x17: 0x60f0000206cc8c98  x18: 0x0000000000000000  x19: 0x000000010d345fd0
   x20: 0x000000016ef65338  x21: 0x00000001075b6558  x22: 0x00000001075b48f8  x23: 0x000000010d356290
   x24: 0x0000000000000000  x25: 0x000000016ef65420  x26: 0x0000000000000000  x27: 0x0000000206cc8c68
   x28: 0x00000001033c9d18   fp: 0x000000016ef65380   lr: 0x0000000101ae8b5c
    sp: 0x000000016ef65300   pc: 0x0000000101ae8b90 cpsr: 0x60001000
   esr: 0xf2000001 (Breakpoint) brk 1


Binary Images:
        0x100e98000 -         0x10332ffff IKO arm64  <1c0e2219a9be358a96a9e16e51e8431f> /var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/IKO
        0x103fec000 -         0x103ff3fff CGRPCZlib arm64  <be8f5cb412be37b9b366ca4fcba83da5> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CGRPCZlib.framework/CGRPCZlib
        0x104004000 -         0x104013fff CNIOAtomics arm64  <0dd4f6a7b71533a09217f0f144ec9aa1> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CNIOAtomics.framework/CNIOAtomics
        0x104030000 -         0x104037fff CNIOBoringSSLShims arm64  <ce837759a7a5341cbe2186000f8e4ca5> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CNIOBoringSSLShims.framework/CNIOBoringSSLShims
        0x104048000 -         0x10404ffff CNIODarwin arm64  <8b2f1f43a3cb3ecda56f340c55180fef> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CNIODarwin.framework/CNIODarwin
        0x104060000 -         0x10406bfff CNIOHTTPParser arm64  <d1c97550b9303f55bd62ae17d76a53b3> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CNIOHTTPParser.framework/CNIOHTTPParser
        0x104120000 -         0x104127fff CNIOLinux arm64  <2fb543b567c43203b318c7ac27859f56> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CNIOLinux.framework/CNIOLinux
        0x104138000 -         0x10413ffff CNIOWindows arm64  <f78cb3886d0f3edf9e40a96eca5e8547> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CNIOWindows.framework/CNIOWindows
        0x1041b8000 -         0x104353fff CNIOBoringSSL arm64  <97b9fbeb700a36cd8e1fde55a8ad5d40> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CNIOBoringSSL.framework/CNIOBoringSSL
        0x10446c000 -         0x10453ffff GRPC arm64  <a0abdbf2731939a689798a26a7d44ad0> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/GRPC.framework/GRPC
        0x104720000 -         0x104793fff Lekta arm64  <e8617f45ed5a39f5bc41545754c256f1> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Lekta.framework/Lekta
        0x1048b0000 -         0x1048bffff Logging arm64  <6ad9bed3009137f6b093a5028d97568a> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Logging.framework/Logging
        0x1048e8000 -         0x1048effff NIO arm64  <5be0892518c03c4a9e5047895d602d9b> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIO.framework/NIO
        0x104900000 -         0x10490bfff NIOConcurrencyHelpers arm64  <5cd0ff32f36934aab6cae74179d8d8a5> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOConcurrencyHelpers.framework/NIOConcurrencyHelpers
        0x104958000 -         0x1049bbfff NIOCore arm64  <8118e7029003373297e756a37ab0d8fb> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOCore.framework/NIOCore
        0x104aac000 -         0x104abbfff NIOEmbedded arm64  <1a864c97710239e5b812a2718f4f82e9> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOEmbedded.framework/NIOEmbedded
        0x104ae4000 -         0x104afffff NIOExtras arm64  <90c76ae220df356a844c21f03691d756> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOExtras.framework/NIOExtras
        0x104b54000 -         0x104b5bfff NIOFoundationCompat arm64  <d680fe89ce813031869171ab65918910> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOFoundationCompat.framework/NIOFoundationCompat
        0x104b78000 -         0x104b9bfff NIOHPACK arm64  <8e33278c3a4b352c923a18e1ce6b303d> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOHPACK.framework/NIOHPACK
        0x104be0000 -         0x104c17fff NIOHTTP1 arm64  <402daa3710b83c2dbd9980390f9358b2> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOHTTP1.framework/NIOHTTP1
        0x104c8c000 -         0x104d13fff NIOHTTP2 arm64  <1856a51c5dde38dcacbfa69370c19aba> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOHTTP2.framework/NIOHTTP2
        0x104e18000 -         0x104e7bfff NIOPosix arm64  <465afaef14483e999d2dc50912b589b2> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOPosix.framework/NIOPosix
        0x104f30000 -         0x104f63fff NIOSSL arm64  <f3a73bdd9f673ab4a7d8e23a5f626e42> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOSSL.framework/NIOSSL
        0x104fe4000 -         0x104feffff NIOTLS arm64  <2f2d4c6db6843f848c0ba5b26b18567d> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOTLS.framework/NIOTLS
        0x10500c000 -         0x10503bfff NIOTransportServices arm64  <b8e7b9b9c4c9315782c323aa1978ebf4> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NIOTransportServices.framework/NIOTransportServices
        0x1050b0000 -         0x1050b7fff NativeAlgorithms arm64  <bf287c10aefe3a62bf8c06d2caf0d004> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NativeAlgorithms.framework/NativeAlgorithms
        0x1050c8000 -         0x1051cffff SwiftProtobuf arm64  <cc46805f7d6f33a0ada5aafa9ae37e62> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/SwiftProtobuf.framework/SwiftProtobuf
        0x105408000 -         0x10540ffff _NIODataStructures arm64  <75ae4ac94dec36a6a2978b42c4cc67d4> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/_NIODataStructures.framework/_NIODataStructures
        0x105428000 -         0x105ef7fff native arm64  <0dc2d8a82218329783806750c09e8889> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/native.framework/native
        0x106b30000 -         0x106b3bfff Assembly arm64  <fb567a2779c63809ab6f9ddca323b23d> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Assembly.framework/Assembly
        0x106b4c000 -         0x106b77fff Assets arm64  <21e04e8ec6eb3ccfae59d3edf3bc67f6> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Assets.framework/Assets
        0x106b9c000 -         0x106bcffff CommonModels arm64  <206977b7db63356dbe494543903dc0ab> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CommonModels.framework/CommonModels
        0x106c08000 -         0x106d2bfff ComposableArchitecture arm64  <e0219c7c0b8739c2a09758559182ce90> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/ComposableArchitecture.framework/ComposableArchitecture
        0x106dac000 -         0x106db3fff DateUtils arm64  <d40c36b8d0793601a7274ba7301f1eb3> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DateUtils.framework/DateUtils
        0x106dc4000 -         0x106df7fff Dependencies arm64  <7f156887c4a83c8a9dffef7661965888> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Dependencies.framework/Dependencies
        0x106e18000 -         0x106e1ffff DependenciesMacros arm64  <8658025c111734c58e1e851955b6780b> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DependenciesMacros.framework/DependenciesMacros
        0x106e34000 -         0x106e3bfff DesignSystem arm64  <fabb9a98800731aab7e6a0ae2a05c706> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DesignSystem.framework/DesignSystem
        0x106e4c000 -         0x106e53fff DesignSystemConfigStub arm64  <cbbf8b46624f381bbbb070b866d0d8c7> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DesignSystemConfigStub.framework/DesignSystemConfigStub
        0x106e60000 -         0x106fe7fff DesignSystemSwiftUI arm64  <6ed071eb055b3839bc177f4fd30a9067> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DesignSystemSwiftUI.framework/DesignSystemSwiftUI
        0x1070cc000 -         0x1070ebfff DesignSystemTokens arm64  <252dfa6550363fcdb88fcbb82a15103f> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DesignSystemTokens.framework/DesignSystemTokens
        0x107110000 -         0x1072a3fff DesignSystemUIKit arm64  <870a05bc43c135b9a8c1aa4fa5a71cc9> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DesignSystemUIKit.framework/DesignSystemUIKit
        0x107364000 -         0x1073d3fff IKOCommon arm64  <4b37f8df17513765ac269082a07a757c> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/IKOCommon.framework/IKOCommon
        0x107440000 -         0x10747ffff InputBarAccessoryView arm64  <ab3077c83d6736ee99109c89840bbde6> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/InputBarAccessoryView.framework/InputBarAccessoryView
        0x1074ac000 -         0x1074b7fff Logger arm64  <db619ce38a4635f3a86e882395bccf8a> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Logger.framework/Logger
        0x1074c8000 -         0x1074d7fff NetworkModule arm64  <d0cfd0f7196239d4b439a275ee6b1d6d> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/NetworkModule.framework/NetworkModule
        0x1074f0000 -         0x107503fff PersistentStorage arm64  <28790aabcb2b3acb861778e5bfd848ed> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/PersistentStorage.framework/PersistentStorage
        0x10751c000 -         0x107527fff Session arm64  <519fd8d2835c359983438e27508f714c> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Session.framework/Session
        0x10753c000 -         0x107553fff SnapKit arm64  <2e26f3e29ea93062ac719acdb6e76929> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/SnapKit.framework/SnapKit
        0x10756c000 -         0x10757bfff SwiftUIUIKitWrapper arm64  <d014d76866823ad2bf80fa12ed715465> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/SwiftUIUIKitWrapper.framework/SwiftUIUIKitWrapper
        0x107590000 -         0x1075b3fff Swinject arm64  <f36b1d658f323e8ab785ee1be8f89661> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Swinject.framework/Swinject
        0x1075cc000 -         0x10763ffff SwinjectAutoregistration arm64  <44cef0eb2c2d3550b1236dfe89bae7a5> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/SwinjectAutoregistration.framework/SwinjectAutoregistration
        0x107654000 -         0x10765bfff UserActivityMonitor arm64  <1a5e70cf74733bad85eeb1c83361aa09> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/UserActivityMonitor.framework/UserActivityMonitor
        0x10766c000 -         0x107673fff UserContext arm64  <ceac6199033e36e2a28a1c2622b38ad2> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/UserContext.framework/UserContext
        0x107684000 -         0x10768bfff _LottieStub arm64  <cf7a03b299ef3159990b9ea95404be90> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/_LottieStub.framework/_LottieStub
        0x10769c000 -         0x1076a3fff DACircularProgress arm64  <531a69216f7837c5841624d19bad67ea> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DACircularProgress.framework/DACircularProgress
        0x1076b8000 -         0x1076c7fff Masonry arm64  <4151226c5d3a3e9dbbf3deb41093d6dd> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Masonry.framework/Masonry
        0x1076e4000 -         0x1076effff FtqResizeViewOnTouch arm64  <c394d62457983afea801bbfdf108a848> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/FtqResizeViewOnTouch.framework/FtqResizeViewOnTouch
        0x107700000 -         0x10770ffff FtqStandardIdentifiers arm64  <e232209e93253fae93e93b4a917d84fd> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/FtqStandardIdentifiers.framework/FtqStandardIdentifiers
        0x107720000 -         0x1078e3fff Lottie arm64  <4c5219a480bf3b5fa4f4c38d50491047> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Lottie.framework/Lottie
        0x107990000 -         0x1079a3fff CasePaths arm64  <2e45b0c1f0f130978cf43bdc2de32ac0> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CasePaths.framework/CasePaths
        0x1079bc000 -         0x1079dbfff CombineSchedulers arm64  <5072046fcb8038529e0184286ef8a87a> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CombineSchedulers.framework/CombineSchedulers
        0x1079f8000 -         0x107a07fff ConcurrencyExtras arm64  <289a7f2458363ac081e89c21d3207e37> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/ConcurrencyExtras.framework/ConcurrencyExtras
        0x107a20000 -         0x107a2ffff DesignSystemAssets arm64  <56ee0a1087703a498ee1c383fd391959> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DesignSystemAssets.framework/DesignSystemAssets
        0x107a44000 -         0x107af3fff DesignSystemPreview arm64  <8f66f58a4513324ca953fcfe829a179d> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/DesignSystemPreview.framework/DesignSystemPreview
        0x107b5c000 -         0x107b6ffff IdentifiedCollections arm64  <30454dadcd6a3d508d0bee8e02e9c2ba> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/IdentifiedCollections.framework/IdentifiedCollections
        0x107b84000 -         0x107b9ffff IssueReporting arm64  <6a40b8bb022d3a75b5453b82ca7f8305> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/IssueReporting.framework/IssueReporting
        0x107bb8000 -         0x107be3fff OrderedCollections arm64  <df309c5f183f3e799c2a22371e35ee01> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/OrderedCollections.framework/OrderedCollections
        0x107c04000 -         0x107c1bfff Perception arm64  <de2f65a389f0378884235e025cc255a8> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Perception.framework/Perception
        0x107c38000 -         0x107c6bfff CustomDump arm64  <77bc0db5bd543dbcba3adb1f093da507> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/CustomDump.framework/CustomDump
        0x107c8c000 -         0x107c97fff InternalCollectionsUtilities arm64  <4d15049c7a883600a847b89384cf915d> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/InternalCollectionsUtilities.framework/InternalCollectionsUtilities
        0x107ca8000 -         0x107cb7fff XCTestDynamicOverlay arm64  <5738623c21a53777a2c1dc268229c430> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/XCTestDynamicOverlay.framework/XCTestDynamicOverlay
        0x107cd0000 -         0x107cd7fff Reachability arm64  <e36734077e2732a3b87ae09713c648cb> /private/var/containers/Bundle/Application/0AA11F38-44BA-4EF1-8E22-80C756023BCC/IKO.app/Frameworks/Reachability.framework/Reachability
        0x108154000 -         0x10815ffff libobjc-trampolines.dylib arm64e  <a068c18d51c33c9aa2875c9c122ada7d> /private/preboot/Cryptexes/OS/usr/lib/libobjc-trampolines.dylib
        0x197f32000 -         0x197fd0ad7 dyld arm64e  <ef27e3863cff3752b152d96a0aa9effd> /usr/lib/dyld
        0x197fec000 -         0x1985772ff libswiftCore.dylib arm64e  <fc4d41760f93347e8138e20c2734660b> /usr/lib/swift/libswiftCore.dylib
        0x198578000 -         0x1993be7df Foundation arm64e  <218da4dc727a3341b59e8fdb39a2d7c4> /System/Library/Frameworks/Foundation.framework/Foundation
        0x1993bf000 -         0x19944826f libswift_Concurrency.dylib arm64e  <d785a303cb4a30228462001cd20258e3> /usr/lib/swift/libswift_Concurrency.dylib
        0x19af02000 -         0x19b4865ff CoreFoundation arm64e  <b4a0233bf37d3ef6a977e4f36199c5a4> /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
        0x1a0845000 -         0x1a2c930df UIKitCore arm64e  <a0e1cefbfd0136f9b82351b092e4dbc6> /System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore
        0x1ab237000 -         0x1ab24dcb8 libswiftDispatch.dylib arm64e  <cf915552e1a5365e9915d26839764bdc> /usr/lib/swift/libswiftDispatch.dylib
        0x1b1d97000 -         0x1b1e8cbb7 Combine arm64e  <42145ecaab5e3f5dbf02cc84fadc8d6f> /System/Library/Frameworks/Combine.framework/Combine
        0x1d335f000 -         0x1d33a525f libdispatch.dylib arm64e  <6a1b4fabb32633738bab8e8464c68c66> /usr/lib/system/libdispatch.dylib
        0x1f6f69000 -         0x1f6f7544f libsystem_pthread.dylib arm64e  <6e1be86b581a306790653412103e1df4> /usr/lib/system/libsystem_pthread.dylib
        0x23bb3f000 -         0x23bb477ff GraphicsServices arm64e  <3688150f0fff38a4914910b3c47b53b1> /System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices
        0x24485b000 -         0x244895d2b libsystem_kernel.dylib arm64e  <ff136c45738b3f6e82e57340e51a1478> /usr/lib/system/libsystem_kernel.dylib

EOF
