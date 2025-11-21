#import "IKOMainAssembly.h"
#import "IKOServerSideTeaserWidget.h"
#import <UIComponents/IKOModalLayerContentView.h>
#import <UIComponents/IKOTipViewController.h>

@class IKOTeaserWithBlueButtonViewController;
@class IKOCompressedTeaserWithBlueButtonViewController;
@class IKOBaseViewController;
@protocol IKOModalLayerEmbeddable;

@interface IKOMainAssembly (Teaser)

- (IKOCompressedTeaserWithBlueButtonViewController *)p2pAliasTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)biometricsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)activationTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)transferRequestTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)standingOrdersTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)batchTransferTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)shortcutsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)personalizationTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)moneyboxesTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)forcetouchTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)directDebitsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)qrListTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)cdmTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)operationConfirmationTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)uncompletedTransfersTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)ownNameUpdateTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)copyBlikViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)panicButtonTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)paymentInstrumentViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)scheduledNotificationsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)applePayTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)mobileAuthorizationActiveTeaserViewController;
- (IKOTeaserWithBlueButtonViewController *)mobileAuthorizationPassiveTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)transportTicketsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)parkingTicketsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)motoInsuranceTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)giftCardTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)openBankingAisTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)openBankingRelationsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)resetPasswordTeaserViewController;
- (IKOTipViewController *)talk2IKOTipViewController;
- (IKOTipViewController *)dailyWidgetTipViewController;
- (IKOTipViewController *)dailyWidgetPfmTipViewController;
- (IKOBaseViewController <IKOModalLayerEmbeddable> *)highwayTicketsTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)talk2IKOTeaserViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)splitTransferTeaserViewController;
- (IKOTipViewController *)universalSearchTipViewController;
- (IKOCompressedTeaserWithBlueButtonViewController *)behavioralBiometricTeaserViewController

- (IKOCompressedTeaserWithBlueButtonViewController *)genericTeaserViewControllerWithTitle:(NSString *)title subtitle:(NSString *)subtitle buttonName:(NSString *)buttonName image:(UIImage *)image;

@end





#import "Defines.h"
#import "IKO-Swift.h"
#import "IKOActivationStartViewController.h"
#import "IKOMainAssembly+GiftCards.h"
#import "IKOMainAssembly+P2P.h"
#import "IKOMainAssembly+Products.h"
#import "IKOMainAssembly+Settings.h"
#import "IKOMainAssembly+Teaser.h"
#import "IKOMainViewController.h"
#import "IKONotActiveViewController.h"
#import "IKOP2PAliasRegistrationTeaserViewController.h"
#import "IKOP2PUserInfo.h"
#import "IKORestrictionsManager.h"
#import "IKORootViewController.h"
#import "IKOTeaserWithBlueAndWhiteButtonViewController.h"
#import "UIViewController+ModalTransition.h"
#import <Assets/Assets-Swift.h>
#import <Behex/Behex-Swift.h>
#import <BehexDefinitions/IKOBehexEventIdMapping.h>
#import <Highways/Highways-Swift.h>
#import <IKOCommon/IKOCommon-Swift.h>
#import <IKOCommon/IKODefines.h>
#import <ParkingPlaces/ParkingPlaces-Swift.h>
#import <PassKit/PassKit.h>
#import <TransportTickets/TransportTickets-Swift.h>
#import <UIComponents/IKOCompressedTeaserWithBlueButtonViewController.h>
#import <UIComponents/IKOModalLayerViewController.h>
#import <UIComponents/IKOTipViewController.h>
#import <UIComponents/UIComponents-Swift.h>
#import <UIComponents/UIViewController+ChildViewController.h>
#import <UniversalSearch/UniversalSearch-Swift.h>
#import <native/nc_platform_initializer/gen/iko-json-labels-objc.h>

@implementation IKOMainAssembly (Teaser)

- (IKOCompressedTeaserWithBlueButtonViewController *)p2pAliasTeaserViewController {
    IKOP2PAliasRegistrationTeaserViewController *controller = [[IKOP2PAliasRegistrationTeaserViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_P2PTransfer_lbl_Title
                                                                                                                        subtitle:IKOLocalizedLabel_Teaser_P2PTransfer_lbl_Subtitle
                                                                                                                     buttonTitle:IKOLocalizedLabel_Teaser_P2PTransfer_btn_OK
                                                                                                                           image:[Assets imageNamed:IKOImages.IC_TEASER_P2P]
                                                                                                                       orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        strongify(weakSelf);

        UIViewController *viewController;
        switch ([IKOP2PUserInfo sharedInfo].p2pStatus) {
            case PS_OTHER_ISS_ALIAS:
                viewController = [[IKOMainAssembly mainAssembly] p2pAliasViewControllerWithType:IKOP2PAliasActionTypeChange
                                                                                    phoneNumber:[IKOP2PUserInfo sharedInfo].msisdn];
                break;
            case PS_OWN_ALIAS:
            case PS_NO_ALIAS:
            case PS_IMPOSSIBLE:
            case PS_IN_PROGRESS:
            case PS_UNKNOWN:
                viewController = [[IKOMainAssembly mainAssembly] p2pAliasViewControllerWithType:IKOP2PAliasActionTypeRegister
                                                                                    phoneNumber:[IKOP2PUserInfo sharedInfo].msisdn];
                break;
        }

        [strongSelf.controllerToPresentModalOn presentViewController:[IKOAssembler resolveIKOBaseNavigationControllerWithRoot:viewController]
                                                            animated:YES
                                                      transitionType:IKORouterTransitionTypeStandard
                                                          completion:nil];

        [weakController.modalLayerViewController dismiss];
    };

    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)biometricsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller;
    NSObject<IKOBiometricsProtocol> *biometrics = [IKOAssembler resolveIKOBiometricsProtocol];
    switch (biometrics.biometryType) {
        case IKOBiometryTypeTouchID:
            controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_BiometricAuthentication_InvalidationTeaser_lbl_TouchIDTitle
                                                                             subtitle:IKOLocalizedLabel_BiometricAuthentication_InvalidationTeaser_lbl_TouchIDSubtitle
                                                                          buttonTitle:IKOLocalizedLabel_Teaser_TouchID_btn_OK
                                                                                image:[Assets imageNamed:IKOImages.IC_TEASER_TOUCHID]
                                                                            orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
            break;
        case IKOBiometryTypeFaceID:
            controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_BiometricAuthentication_InvalidationTeaser_lbl_FaceIDTitle
                                                                             subtitle:IKOLocalizedLabel_BiometricAuthentication_InvalidationTeaser_lbl_FaceIDSubtitle
                                                                          buttonTitle:IKOLocalizedLabel_Teaser_FaceID_btn_OK
                                                                                image:[Assets imageNamed:IKOImages.IC_TEASER_FACEID]
                                                                            orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
            break;
        case IKOBiometryTypeNone:
            break;
    }

    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [[IKOAssembler resolveIKONativeRedirecting] performNativeRedirectWithInAppIdentifier:IKOInAppRedirectSettingsTouchID
                                                                                 arguments:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)activationTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_Activation_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_Activation_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_Activation_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_ACTIVATION]
                                                                                                                               orderType: IKOCompressedTeaseViewOrderTypeTextFirst];
    controller.behexEventId = Activation_Required_view_Show;
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        strongify(weakSelf);
        [[IKOAssembler resolveBehex] registerWithEvent:Activation_Required_btn_Activate];
        if ([IKORestrictionsManager sharedManager].isSignatureMissing) {
            [weakController.modalLayerViewController dismissWithCompletion:^{
                id<IKOModalLayerProtocol> modalLayer = [[IKOAssembler resolveIKOMainAssemblyRestrictions] signatureMissingModalLayerViewController];
                [modalLayer showOnViewController:strongSelf.controllerToPresentModalOn.navigationController dismissCompletion:nil];
            }];
        } else {
            [strongSelf.controllerToPresentModalOn presentViewController:[[IKOAssembler resolveIKOMainAssemblyActivation] activationNavigationViewControllerWithDelegate:nil]
                                                                animated:YES
                                                          transitionType:IKORouterTransitionTypeStandard
                                                              completion:nil];
            [weakController.modalLayerViewController dismiss];
        }
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)transferRequestTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_C2CTransferRequest_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_C2CTransferRequest_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_C2CTransferRequest_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_C2CTRANSFERREQUEST]
                                                                                                            orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)standingOrdersTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_StandingOrders_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_StandingOrders_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_StandingOrders_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_STANDINGORDERS]
                                                                                                            orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)batchTransferTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_BatchTransfer_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_BatchTransfer_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_BatchTransfer_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_BATCHTRANSFER]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)shortcutsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_Shortcuts_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_Shortcuts_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_Shortcuts_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_SHORTCUTS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)personalizationTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_Customization_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_Customization_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_Customization_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_PERSONALIZATION]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)moneyboxesTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_Moneyboxes_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_Moneyboxes_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_Moneyboxes_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_MONEYBOXES]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        strongify(weakSelf);

        IKOBaseViewController *createMoneyboxViewController = [IKOAssembler resolveIKOChooseNewMoneyBoxCategoryViewControllerProtocol:nil];
        __weak typeof(createMoneyboxViewController) weakCreateMoneyboxViewController = createMoneyboxViewController;
        [createMoneyboxViewController setupLeftBarButtonItemWithType:IKOLeftNavigationButtonItemTypeCancel handler:^(id sender) {
            [weakCreateMoneyboxViewController dismissViewControllerAnimated:YES completion:nil];
        }];

        [strongSelf.controllerToPresentModalOn presentViewController:[IKOAssembler resolveIKOBaseNavigationControllerWithRoot:createMoneyboxViewController]
                                                            animated:YES
                                                      transitionType:IKORouterTransitionTypeStandard
                                                          completion:nil];

        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)forcetouchTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_ForceTouch_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_ForceTouch_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_ForceTouch_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_FORCE_TOUCH]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)directDebitsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_DirectDebits_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_DirectDebits_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_DirectDebits_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_DIRECT_DEBITS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)qrListTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_QRList_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_QRList_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_QRList_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_QR_LIST]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)cdmTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_CDM_Teaser_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_CDM_Teaser_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_CDM_Teaser_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_CMD]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)operationConfirmationTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_OperationConfirmation_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_OperationConfirmation_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_OperationConfirmation_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_OPERATION_CONFIRMATION]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)uncompletedTransfersTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_UncompletedTransfers_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_UncompletedTransfers_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_UncompletedTransfers_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_UNCOMPLETED_TRANSFERS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)ownNameUpdateTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_OwnNameUpdate_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_OwnNameUpdate_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_OwnNameUpdate_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_OWN_NAME_UPDATE]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)copyBlikViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_CopyBlik_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_CopyBlik_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_CopyBlik_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_COPY_BLIK]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)panicButtonTeaserViewController {
    return [self genericTeaserViewControllerWithTitle:IKOLocalizedLabel_Teaser_PanicButton_lbl_Title
                                             subtitle:IKOLocalizedLabel_Teaser_PanicButton_lbl_Subtitle
                                           buttonName:IKOLocalizedLabel_Teaser_PanicButton_btn_OK
                                                image:[Assets imageNamed:IKOImages.IKO_TEASER_PANIC_BUTTON]];

}

- (IKOCompressedTeaserWithBlueButtonViewController *)paymentInstrumentViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_PaymentInstrument_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_PaymentInstrument_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_PaymentInstrument_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_PAYMENT_INSTRUMENT]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)scheduledNotificationsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_ScheduledNotifications_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_ScheduledNotifications_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_ScheduledNotifications_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_SCHEDULED_NOTIFICATIONS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)applePayTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_ApplePay_lbl_Title
                                                                                                                                subtitle:IKOLocalizedLabel_Teaser_ApplePay_lbl_Subtitle
                                                                                                                             buttonTitle:IKOLocalizedLabel_Teaser_ApplePay_btn_OK
                                                                                                                                   image:[Assets imageNamed:IKOImages.IC_APPLE_PAY]
                                                                                                                               orderType:IKOCompressedTeaseViewOrderTypeImageFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        PKPassLibrary *passLibrary = [PKPassLibrary new];
        [passLibrary openPaymentSetup];
        [weakController.modalLayerViewController dismiss];

    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)mobileAuthorizationActiveTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationActive_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_MobileAuthorizationActive_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationActive_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_MOBILEAUTHORIZATION]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        strongify(weakSelf);

        UIViewController *viewController = [[IKOMainAssembly mainAssembly] settingsMAViewControllerWithPreselected:IKOCoreAuthToolMobileApplication];
        [strongSelf.controllerToPresentModalOn presentViewController:[IKOAssembler resolveIKOBaseNavigationControllerWithRoot:viewController]
                                                            animated:YES
                                                      transitionType:IKORouterTransitionTypeStandard
                                                          completion:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOTeaserWithBlueAndWhiteButtonViewController *)mobileAuthorizationPassiveTeaserViewController {
    IKOTeaserWithBlueAndWhiteButtonViewController *controller = [[IKOTeaserWithBlueAndWhiteButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_lbl_Title
                                                                                                                            subtitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_lbl_Subtitle
                                                                                                                     blueButtonTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_btn_OK
                                                                                                                    whiteButtonTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_btn_ActivationBenefits
                                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_MOBILEAUTHORIZATION]];
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.blueButtonHandler = ^{
        strongify(weakSelf);
        [[IKOAssembler resolveBehex] registerWithEvent:Activation_Required_btn_Activate];
        if ([IKORestrictionsManager sharedManager].isSignatureMissing) {
            [weakController.modalLayerViewController dismissWithCompletion:^{
                id<IKOModalLayerProtocol> modalLayer = [[IKOAssembler resolveIKOMainAssemblyRestrictions] signatureMissingModalLayerViewController];
                [modalLayer showOnViewController:strongSelf.controllerToPresentModalOn.navigationController dismissCompletion:nil];
            }];
        } else {
            [strongSelf.controllerToPresentModalOn presentViewController:[[IKOAssembler resolveIKOMainAssemblyActivation] activationNavigationViewControllerWithDelegate:nil]
                                                                animated:YES
                                                          transitionType:IKORouterTransitionTypeStandard
                                                              completion:nil];
            [weakController.modalLayerViewController dismiss];
        }
    };
    controller.whiteButtonHandler = ^{
        strongify(weakSelf);
        IKONotActiveViewController *notActiveViewController = [[IKOAssembler resolveIKOMainAssemblyRestrictions] notActiveViewControllerWithOriginalViewController:strongSelf.controllerToPresentModalOn.navigationController];
        [strongSelf.controllerToPresentModalOn presentViewController:[IKOAssembler resolveIKOBaseNavigationControllerWithRoot:notActiveViewController]
                               animated:YES
                         transitionType:IKORouterTransitionTypeStandard
                             completion:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)transportTicketsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_TransportTickets_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_TransportTickets_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_TransportTickets_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_TRANSPORTTICKETS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        strongify(weakSelf);

        UIViewController *viewController = [IKOAssembler resolveTransportTicketsListOrRegulationsViewController];
        [strongSelf.controllerToPresentModalOn presentViewController:[IKOAssembler resolveIKOBaseNavigationControllerWithRoot:viewController]
                                                            animated:YES
                                                      transitionType:IKORouterTransitionTypeStandard
                                                          completion:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)parkingTicketsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_Parkings_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_Parkings_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_Parkings_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_PARKINGTICKETS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)motoInsuranceTeaserViewController {
    return [self genericTeaserViewControllerWithTitle:IKOLocalizedLabel_Teaser_MotoInsurance_lbl_Title
                                             subtitle:IKOLocalizedLabel_Teaser_MotoInsurance_lbl_Subtitle
                                           buttonName:IKOLocalizedLabel_Teaser_MotoInsurance_btn_OK
                                                image:[Assets imageNamed:IKOImages.IC_TEASER_MOTO_INSURANCE]];
}

- (IKOCompressedTeaserWithBlueButtonViewController *)resetPasswordTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_PasswordReset_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_PasswordReset_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_PasswordReset_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_RESET_PASSWORD]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];

    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)giftCardTeaserViewController {
    return [self genericTeaserViewControllerWithTitle:IKOLocalizedLabel_Teaser_GiftCards_lbl_Title
                                             subtitle:IKOLocalizedLabel_Teaser_GiftCards_lbl_Subtitle
                                           buttonName:IKOLocalizedLabel_Teaser_GiftCards_btn_OK
                                                image:[Assets imageNamed:IKOImages.IC_TEASER_GIFTCARDS]];
}

- (IKOCompressedTeaserWithBlueButtonViewController *)openBankingAisTeaserViewController {

    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_OpenBanking_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_OpenBanking_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_OpenBanking_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_OPENBANKING_AIS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];

    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [[IKOAssembler resolveIKONativeRedirecting] performNativeRedirectWithInAppIdentifier:IKOInAppRedirectAddExternalAccount arguments:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)openBankingRelationsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_OpenBankingAccountRelations_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_OpenBankingAccountRelations_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_OpenBankingAccountRelations_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_OPENBANKING_AIS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];

    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [[IKOAssembler resolveIKONativeRedirecting] performNativeRedirectWithInAppIdentifier:IKOInAppRedirectRelationsExternalAccounts arguments:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)genericTeaserViewControllerWithTitle:(NSString *)title subtitle:(NSString *)subtitle buttonName:(NSString *)buttonName image:(UIImage *)image {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:title
                                                                                                            subtitle:subtitle
                                                                                                         buttonTitle:buttonName
                                                                                                               image:image
                                                                                                            orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)talk2IKOTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_Talk2IKO_lbl_TeaserTitle
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_Talk2IKO_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_Talk2IKO_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_TALK2IKO]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [[IKOAssembler resolveIKONativeRedirecting] performNativeRedirectWithInAppIdentifier:IKOInAppRedirectTalk2IKO arguments:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

#pragma mark - Tooltip

- (IKOTipViewController *)talk2IKOTipViewController {

    void (^dismissHandler)(id, BOOL) = ^(id sender, BOOL tipBubbleTouched) {
        IKOTeaserManager *teaserManager = [IKOTeaserManager sharedInstance];
        [teaserManager dismissTipWindow];
        if (tipBubbleTouched) {
            BOOL wasOnBoardingPresentedForChatBot = [IKOOnBoardingViewController wasOnBoardingPresentedForFeature:IKOOnBoardingFeatureChatBot];
            T2IChatBotStartConversationMode mode = wasOnBoardingPresentedForChatBot ? T2IChatBotStartConversationModeTextWithKeyboard : T2IChatBotStartConversationModeNone;
            [[IKOAssembler resolveIKONativeRedirecting] redirectToT2IViewController:IKOLocalizedLabel_Teaser_Talk2IKO_lbl_ExpenseAnalystMessage
                                                                          forcePush:true
                                                              forceConversationMode:mode];
        }
    };
    IKOTipViewConfiguration *configuration = [[IKOTipViewConfiguration alloc] initWithTitle:IKOLocalizedLabel_Teaser_Talk2IkoFab_lbl_Title
                                                                                description:nil
                                                                           arrowOrientation:IKOTipArrowOrientationBottom
                                                                               viewTemplate:[IKOTipViewTemplate teaserViewTemplate]
                                                                    isUserIntractionEnabled:YES
                                                                       dismissAutomatically:YES
                                                                        dismissTimeInterval:4
                                                                           andActionHandler:dismissHandler];

    return [[IKOTipViewController alloc] initWithConfiguration:configuration];
}

- (IKOTipViewController *)universalSearchTipViewController {
    void (^dismissHandler)(id, BOOL) = ^(id sender, BOOL tipBubbleTouched) {
        IKOTeaserManager *teaserManager = [IKOTeaserManager sharedInstance];
        [teaserManager dismissTipWindow];
        if (tipBubbleTouched) {
            id viewController = [IKOAssembler resolveUniversalSearchViewController];
            id navigationViewController = [IKOAssembler resolveIKOBaseNavigationControllerWithRoot:viewController];
            [[IKOAssembler resolveIKORootViewController].router showViewController:navigationViewController
                                                                         showStyle:IKORouterShowStylePresent
                                                                          animated:YES
                                                                        completion:nil];
        }
    };
    IKOTipViewConfiguration *configuration = [[IKOTipViewConfiguration alloc] initWithTitle:IKOLocalizedLabel_LiveSearch_Search_lbl_InfoTipTitle
                                                                                description:IKOLocalizedLabel_LiveSearch_Search_lbl_InfoTipSubtitle
                                                                           arrowOrientation:IKOTipArrowOrientationTop
                                                                               viewTemplate:[IKOTipViewTemplate defaultViewTemplate]
                                                                    isUserIntractionEnabled:YES
                                                                       dismissAutomatically:YES
                                                                        dismissTimeInterval:4
                                                                           andActionHandler:dismissHandler];

    return [[IKOTipViewController alloc] initWithConfiguration:configuration];
}

- (IKOTipViewController *)dailyWidgetTipViewController {
    void (^dismissHandler)(id, BOOL) = ^(id sender, BOOL tipBubbleTouched) {
        IKOTeaserManager *teaserManager = [IKOTeaserManager sharedInstance];
        [teaserManager dismissTipWindow];
    };
    IKOTipViewConfiguration *configuration = [[IKOTipViewConfiguration alloc] initWithTitle:IKOLocalizedLabel_Teaser_Daily_lbl_Title
                                                                                description:nil
                                                                           arrowOrientation:IKOTipArrowOrientationBottom
                                                                               viewTemplate:[IKOTipViewTemplate teaserViewTemplate]
                                                                    isUserIntractionEnabled:YES
                                                                       dismissAutomatically:YES
                                                                        dismissTimeInterval:4
                                                                           andActionHandler:dismissHandler];

    return [[IKOTipViewController alloc] initWithConfiguration:configuration];
}

- (IKOTipViewController *)dailyWidgetPfmTipViewController {
    void (^dismissHandler)(id, BOOL) = ^(id sender, BOOL tipBubbleTouched) {
        IKOTeaserManager *teaserManager = [IKOTeaserManager sharedInstance];
        [teaserManager dismissTipWindow];
    };
    IKOTipViewConfiguration *configuration = [[IKOTipViewConfiguration alloc] initWithTitle:IKOLocalizedLabel_Teaser_DailyPFM_lbl_Title
                                                                                description:nil
                                                                           arrowOrientation:IKOTipArrowOrientationBottom
                                                                               viewTemplate:[IKOTipViewTemplate teaserViewTemplateWithArrowOffset:0]
                                                                    isUserIntractionEnabled:YES
                                                                       dismissAutomatically:YES
                                                                        dismissTimeInterval:4
                                                                           andActionHandler:dismissHandler];

    return [[IKOTipViewController alloc] initWithConfiguration:configuration];
}

- (IKOBaseViewController <IKOModalLayerEmbeddable> *)highwayTicketsTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_Highways_lbl_Title
                                                                                                            subtitle:IKOLocalizedLabel_Teaser_Highways_lbl_Subtitle
                                                                                                         buttonTitle:IKOLocalizedLabel_Teaser_Highways_btn_OK
                                                                                                               image:[Assets imageNamed:IKOImages.IC_TEASER_HIGHWAY_TICKETS]
                                                                                                           orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        strongify(weakSelf);
        UIViewController *highwayInitialViewController = [IKOAssembler resolveHighwaysMainRouter];

        [strongSelf.controllerToPresentModalOn presentViewController:[IKOAssembler resolveIKOBaseNavigationControllerWithRoot:highwayInitialViewController]
                                                            animated:YES
                                                      transitionType:IKORouterTransitionTypeStandard
                                                          completion:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOCompressedTeaserWithBlueButtonViewController *)splitTransferTeaserViewController {
    IKOCompressedTeaserWithBlueButtonViewController *controller = [[IKOCompressedTeaserWithBlueButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_SplitPayment_lbl_Title
                                                                                                                                subtitle:IKOLocalizedLabel_Teaser_SplitPayment_lbl_Subtitle
                                                                                                                             buttonTitle:IKOLocalizedLabel_Teaser_SplitPayment_btn_OK
                                                                                                                                   image:[Assets imageNamed:IKOImages.IKO_TEASER_SPLITTRANSFER]
                                                                                                                               orderType:IKOCompressedTeaseViewOrderTypeTextFirst];
    __weak typeof(controller) weakController = controller;
    controller.buttonHandler = ^{
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

- (IKOTeaserWithBlueAndWhiteButtonViewController *)behavioralBiometricTeaserViewController {
    IKOTeaserWithBlueAndWhiteButtonViewController *controller = [[IKOTeaserWithBlueAndWhiteButtonViewController alloc] initWithTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_lbl_Title
                                                                                                                            subtitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_lbl_Subtitle
                                                                                                                     blueButtonTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_btn_OK
                                                                                                                    whiteButtonTitle:IKOLocalizedLabel_Teaser_MobileAuthorizationPassive_btn_ActivationBenefits
                                                                                                                               image:[Assets imageNamed:IKOImages.IKO_TEASER_MOBILEAUTHORIZATION]];
    weakify(self);
    __weak typeof(controller) weakController = controller;
    controller.blueButtonHandler = ^{
        strongify(weakSelf);
        [[IKOAssembler resolveBehex] registerWithEvent:Activation_Required_btn_Activate];
        if ([IKORestrictionsManager sharedManager].isSignatureMissing) {
            [weakController.modalLayerViewController dismissWithCompletion:^{
                id<IKOModalLayerProtocol> modalLayer = [[IKOAssembler resolveIKOMainAssemblyRestrictions] signatureMissingModalLayerViewController];
                [modalLayer showOnViewController:strongSelf.controllerToPresentModalOn.navigationController dismissCompletion:nil];
            }];
        } else {
            [strongSelf.controllerToPresentModalOn presentViewController:[[IKOAssembler resolveIKOMainAssemblyActivation] activationNavigationViewControllerWithDelegate:nil]
                                                                animated:YES
                                                          transitionType:IKORouterTransitionTypeStandard
                                                              completion:nil];
            [weakController.modalLayerViewController dismiss];
        }
    };
    controller.whiteButtonHandler = ^{
        strongify(weakSelf);
        IKONotActiveViewController *notActiveViewController = [[IKOAssembler resolveIKOMainAssemblyRestrictions] notActiveViewControllerWithOriginalViewController:strongSelf.controllerToPresentModalOn.navigationController];
        [strongSelf.controllerToPresentModalOn presentViewController:[IKOAssembler resolveIKOBaseNavigationControllerWithRoot:notActiveViewController]
                               animated:YES
                         transitionType:IKORouterTransitionTypeStandard
                             completion:nil];
        [weakController.modalLayerViewController dismiss];
    };
    return controller;
}

#pragma mark - Helpers

- (UIViewController *)controllerToPresentModalOn {
    IKOMainViewController *sideMenuViewController = (IKOMainViewController *) [IKOAssembler resolveIKORootViewController].currentViewController;
    UIViewController *viewControllerToPresentOn = sideMenuViewController.contentViewController;
    if ([sideMenuViewController.contentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *) sideMenuViewController.contentViewController;
        viewControllerToPresentOn = navigationController.viewControllers.lastObject;
    }

    return viewControllerToPresentOn;
}

@end
