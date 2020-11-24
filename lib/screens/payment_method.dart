import 'package:ecommerceapp/constants/payment.dart';
import 'package:ecommerceapp/constants/screen_ids.dart';
import 'package:ecommerceapp/controllers/auth_controller.dart';
import 'package:ecommerceapp/controllers/cart_controller.dart';
import 'package:ecommerceapp/controllers/order_controller.dart';
import 'package:ecommerceapp/controllers/shipping_controller.dart';
import 'package:ecommerceapp/screens/thank_you.dart';
import 'package:ecommerceapp/services/paypal_service.dart';
import 'package:ecommerceapp/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';

class PaymentMethod extends StatefulWidget {
  PaymentMethod({Key key}) : super(key: key);
  static String id = PaymentMethod_Screen_Id;

  @override
  _PaymentMethodState createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  var _authController;
  var _cartController;
  var _shippingController;
  var _orderController;

  @override
  void initState() {
    _authController = AuthController();
    _cartController = Provider.of<CartController>(context, listen: false);
    _shippingController =
        Provider.of<ShippingController>(context, listen: false);
    _orderController = Provider.of<OrderController>(context, listen: false);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    var totalItemPrice = _cartController.cart.fold(
        0,
        (previousValue, element) =>
            previousValue + (element.product.price * element.quantity));
    int tax = _orderController.tax;
    int shippingCost = _orderController.shippingCost;

    var total = totalItemPrice + tax + shippingCost;
    String totalToString = total.toString() + '100';

    ProgressDialog pr = ProgressDialog(context);
    pr = ProgressDialog(
      context,
      type: ProgressDialogType.Normal,
      isDismissible: false,
      showLogs: false,
    );
    pr.style(
      message: 'Please wait...',
    );

    final _scaffoldKey = GlobalKey<ScaffoldState>();

    _peformStateReset() {
      _cartController.resetCart();
      _shippingController.reset();
    }

    _handleStripeSucessPayment() async {
      var data = await _authController.getUserIdAndLoginStatus();

      _orderController.registerOrderWithStripePayment(
        _shippingController.getShippingDetails(),
        shippingCost.toString(),
        tax.toString(),
        total.toString(),
        totalItemPrice.toString(),
        data[1],
        STRIPE_PAYMENT,
        _cartController.cart,
      );

      await pr.hide();
      //_peformStateReset();
      Navigator.pushNamed(context, Thanks.id);
    }

    _handleStripeFailurePayment() async {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text('Process cancelled'),
        ),
      );
      await pr.hide();
    }

    _handlePaypalBrainTree(String nonce) async {
      var data = await _authController.getUserIdAndLoginStatus();

      _orderController.processOrderWithPaypal(
        _shippingController.getShippingDetails(),
        shippingCost.toString(),
        tax.toString(),
        total.toString(),
        totalItemPrice.toString(),
        data[1],
        PAY_PAL,
        _cartController.cart,
        nonce,
      );

      await pr.hide();
      _peformStateReset();
      Navigator.pushNamed(context, Thanks.id);
    }

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            'Order summary & Payment method',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.black),
          elevation: 1,
          backgroundColor: Colors.white,
        ),
        body: Container(
          margin: EdgeInsets.only(
            left: 18,
            top: 18,
            right: 18,
          ),
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  //title
                  Text(
                    "Order summary",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        width: .5,
                      ),
                      bottom: BorderSide(
                        width: .5,
                      ),
                      top: BorderSide(
                        width: .5,
                      ),
                    ),
                    children: [
                      //item
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              'Items',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              '\$ $totalItemPrice',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      //shipping
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              'Shipping',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              '\$ $shippingCost',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      //tax
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: Text(
                              'Tax',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              '\$ $tax',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      //total
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              '\$ $total',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  SizedBox(
                    height: 40,
                  ),
                  // Payment
                  Text(
                    "Choose Payment method",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),

                  //paypal
                  ButtonTheme(
                    minWidth: size.width,
                    child: RaisedButton(
                      color: Colors.orange[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () async {
                        await pr.show();
                        var nonce = await PayPalService.processPayment(
                            total.toString(), context);
                        if (nonce != null) {
                          _handlePaypalBrainTree(nonce);
                        }
                        await pr.hide();
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Pay",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: "Pal",
                              style: TextStyle(
                                color: Colors.blue[100],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Text(
                    "or",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  //credit or debit button
                  RaisedButton(
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () async {
                      await pr.show();

                      var result = await StripeService.processPayment(
                          totalToString, 'usd');

                      if (result.success) {
                        _handleStripeSucessPayment();
                      } else {
                        _handleStripeFailurePayment();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Credit or Debit card",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
