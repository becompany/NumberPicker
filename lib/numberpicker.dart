import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:infinite_listview/infinite_listview.dart';

/// Created by Marcin Szałek

///NumberPicker is a widget designed to pick a number between #minValue and #maxValue
class NumberPicker extends StatelessWidget {
  ///height of every list element
  static const double DEFAULT_ITEM_EXTENT = 50.0;

  ///width of list view
  static const double DEFAULT_LISTVIEW_WIDTH = 100.0;

  ///constructor for integer number picker
  NumberPicker.integer({
    Key key,
    @required int initialValue,
    @required this.minValue,
    @required this.maxValue,
    @required this.onChanged,
    this.itemExtent = DEFAULT_ITEM_EXTENT,
    this.listViewWidth = DEFAULT_LISTVIEW_WIDTH,
    this.step = 1,
    this.infiniteLoop = false,
  })
      : assert(initialValue != null),
        assert(minValue != null),
        assert(maxValue != null),
        assert(maxValue > minValue),
        assert(initialValue >= minValue && initialValue <= maxValue),
        assert(step > 0),
        selectedIntValue = initialValue,
        selectedDecimalValue = -1,
        decimalPlaces = 0,
        intScrollController = infiniteLoop
            ? new InfiniteScrollController(
          initialScrollOffset: (initialValue - minValue) ~/ step * itemExtent,)
            : new ScrollController(
          initialScrollOffset: (initialValue - minValue) ~/ step * itemExtent,),
        decimalScrollController = null,
        _listViewHeight = 3 * itemExtent,
        integerItemCount = (maxValue - minValue) ~/ step + 1,
        super(key: key);

  ///constructor for decimal number picker
  NumberPicker.decimal({
    Key key,
    @required double initialValue,
    @required this.minValue,
    @required this.maxValue,
    @required this.onChanged,
    this.decimalPlaces = 1,
    this.itemExtent = DEFAULT_ITEM_EXTENT,
    this.listViewWidth = DEFAULT_LISTVIEW_WIDTH,
  })
      : assert(initialValue != null),
        assert(minValue != null),
        assert(maxValue != null),
        assert(decimalPlaces != null && decimalPlaces > 0),
        assert(maxValue > minValue),
        assert(initialValue >= minValue && initialValue <= maxValue),
        selectedIntValue = initialValue.floor(),
        selectedDecimalValue = ((initialValue - initialValue.floorToDouble()) *
            math.pow(10, decimalPlaces))
            .round(),
        intScrollController = new ScrollController(
          initialScrollOffset: (initialValue.floor() - minValue) * itemExtent,
        ),
        decimalScrollController = new ScrollController(
          initialScrollOffset: ((initialValue - initialValue.floorToDouble()) *
              math.pow(10, decimalPlaces))
              .roundToDouble() *
              itemExtent,
        ),
        _listViewHeight = 3 * itemExtent,
        step = 1,
        integerItemCount = maxValue.floor() - minValue.floor() + 1,
        infiniteLoop = false,
        super(key: key);

  ///called when selected value changes
  final ValueChanged<num> onChanged;

  ///min value user can pick
  final double minValue;

  ///max value user can pick
  final double maxValue;

  ///inidcates how many decimal places to show
  /// e.g. 0=>[1,2,3...], 1=>[1.0, 1.1, 1.2...]  2=>[1.00, 1.01, 1.02...]
  final int decimalPlaces;

  ///height of every list element in pixels
  final double itemExtent;

  ///view will always contain only 3 elements of list in pixels
  final double _listViewHeight;

  ///width of list view in pixels
  final double listViewWidth;

  ///ScrollController used for integer list
  final ScrollController intScrollController;

  ///ScrollController used for decimal list
  final ScrollController decimalScrollController;

  ///Currently selected integer value
  final int selectedIntValue;

  ///Currently selected decimal value
  final int selectedDecimalValue;

  ///Step between elements. Only for integer datePicker
  ///Examples:
  /// if step is 100 the following elements may be 100, 200, 300...
  /// if min=0, max=6, step=3, then items will be 0, 3 and 6
  /// if min=0, max=5, step=3, then items will be 0 and 3.
  final int step;

  ///Repeat values infinitely
  final bool infiniteLoop;

  ///Amount of items
  final int integerItemCount;

  final List<int> _decimalValues = new List();

  //
  //----------------------------- PUBLIC ------------------------------
  //

  animateInt(int valueToSelect) {
    int diff = valueToSelect - minValue.floor();
    int index = diff ~/ step;
    animateIntToIndex(index);
  }

  animateIntToIndex(int index) {
    _animate(intScrollController, index * itemExtent);
  }

  animateDecimal(int decimalValue) {
    _animate(decimalScrollController, _indexFromDecimalValue(decimalValue) *
        itemExtent);
  }

  animateDecimalAndInteger(double valueToSelect) {
    animateInt(valueToSelect.floor());
    animateDecimal(((valueToSelect - valueToSelect.floorToDouble()) *
        math.pow(10, decimalPlaces))
        .round());
  }

  //
  //----------------------------- VIEWS -----------------------------
  //

  ///main widget
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (infiniteLoop) {
      return _integerInfiniteListView(themeData);
    }
    if (decimalPlaces == 0) {
      return _integerListView(themeData);
    } else {
      return new Row(
        children: <Widget>[
          _integerListView(themeData),
          _decimalListView(themeData),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      );
    }
  }

  Widget _integerListView(ThemeData themeData) {
    TextStyle defaultStyle = themeData.textTheme.body1;
    TextStyle selectedStyle =
    themeData.textTheme.headline.copyWith(color: themeData.accentColor);

    var listItemCount = integerItemCount + 2;

    return new NotificationListener(
      child: new Container(
        height: _listViewHeight,
        width: listViewWidth,
        child: new ListView.builder(
          controller: intScrollController,
          itemExtent: itemExtent,
          itemCount: listItemCount,
          cacheExtent: _calculateCacheExtent(listItemCount),
          itemBuilder: (BuildContext context, int index) {
            final int value = _intValueFromIndex(index);

            //define special style for selected (middle) element
            final TextStyle itemStyle =
            value == selectedIntValue ? selectedStyle : defaultStyle;

            bool isExtra = index == 0 || index == listItemCount - 1;

            return isExtra
                ? new Container() //empty first and last element
                : new Center(
              child: new Text(value.toString(), style: itemStyle),
            );
          },
        ),
      ),
      onNotification: _onIntegerNotification,
    );
  }

  Widget _decimalListView(ThemeData themeData) {
    TextStyle defaultStyle = themeData.textTheme.body1;
    TextStyle selectedStyle =
    themeData.textTheme.headline.copyWith(color: themeData.accentColor);

    int decimalItemCount = _initDecimalValues(selectedIntValue.roundToDouble());
    return new NotificationListener(
      child: new Container(
        height: _listViewHeight,
        width: listViewWidth,
        child: new ListView.builder(
          controller: decimalScrollController,
          itemExtent: itemExtent,
          itemCount: decimalItemCount,
          itemBuilder: (BuildContext context, int index) {
            //define special style for selected (middle) element
            final TextStyle itemStyle =
            _decimalValues[index] == selectedDecimalValue ? selectedStyle : defaultStyle;

            bool isExtra = index == 0 || index == decimalItemCount - 1;

            return isExtra
                ? new Container() //empty first and last element
                : new Center(
              child: new Text(
                  _decimalValues[index].toString().padLeft(decimalPlaces, '0'),
                  style: itemStyle),
            );
          },
        ),
      ),
      onNotification: _onDecimalNotification,
    );
  }

  int _initDecimalValues(double selectedValue) {
    final selectedIntValue = selectedValue.floor();
    int decimalItemCount;
    bool reverse = false;
    if(selectedIntValue == maxValue.floor()) {
      decimalItemCount =
          ((maxValue - maxValue.floor()) * math.pow(10, decimalPlaces)).floor()
              + 3;
    } else if(selectedIntValue == minValue.floor()) {
      decimalItemCount =
          ((minValue - minValue.floor()) * math.pow(10, decimalPlaces)).floor()
              + 2;
      reverse = true;
    } else {
      decimalItemCount = math.pow(10, decimalPlaces) + 2;
    }
    _decimalValues.length = decimalItemCount;
    for (var i = 0; i < decimalItemCount; i++) {
      _decimalValues[i] = reverse ? (math.pow(10,
          decimalPlaces) - decimalItemCount + 1) + i : i - 1;
    }
    return decimalItemCount;
  }

  Widget _integerInfiniteListView(ThemeData themeData) {
    TextStyle defaultStyle = themeData.textTheme.body1;
    TextStyle selectedStyle =
    themeData.textTheme.headline.copyWith(color: themeData.accentColor);

    return new NotificationListener(
      child: new Container(
        height: _listViewHeight,
        width: listViewWidth,
        child: new InfiniteListView.builder(
          controller: intScrollController,
          itemExtent: itemExtent,
          itemBuilder: (BuildContext context, int index) {
            final int value = _intValueFromIndex(index);

            //define special style for selected (middle) element
            final TextStyle itemStyle =
            value == selectedIntValue ? selectedStyle : defaultStyle;

            return new Center(
              child: new Text(value.toString(), style: itemStyle),
            );
          },
        ),
      ),
      onNotification: _onIntegerNotification,
    );
  }

  //
  // ----------------------------- LOGIC -----------------------------
  //

  int _intValueFromIndex(int index) {
    index--;
    index %= integerItemCount;
    return minValue.floor() + index * step;
  }

  int _decimalValueFromIndex(int index) {
    return _decimalValues[index];
  }

  int _indexFromDecimalValue(int decimal) {
    return _decimalValues.indexOf(decimal);
  }

  bool _onIntegerNotification(Notification notification) {
    if (notification is ScrollNotification) {
      //calculate
      int intIndexOfMiddleElement = (notification.metrics.pixels / itemExtent)
          .round();
      if (!infiniteLoop) {
        intIndexOfMiddleElement =
            intIndexOfMiddleElement.clamp(0, integerItemCount - 1);
      }
      int intValueInTheMiddle = _intValueFromIndex(intIndexOfMiddleElement + 1);
      intValueInTheMiddle = _normalizeIntegerMiddleValue(intValueInTheMiddle);

      if (_userStoppedScrolling(notification, intScrollController)) {
        //center selected value
        animateIntToIndex(intIndexOfMiddleElement);
        if (decimalPlaces > 0) {
          animateDecimal(selectedDecimalValue - 1);
        }
      }

      //update selection
      if (intValueInTheMiddle != selectedIntValue) {
        num newValue;
        if (decimalPlaces == 0) {
          //return integer value
          newValue = (intValueInTheMiddle);
        } else {
          //return integer+decimal
          double decimalPart = _toDecimal(selectedDecimalValue);
          newValue = ((intValueInTheMiddle + decimalPart).toDouble());
          if (newValue < minValue) {
            _initDecimalValues(minValue);
            animateDecimal(0);
            newValue = minValue;
          } else if (newValue > maxValue) {
            _initDecimalValues(maxValue);
            animateDecimal(((maxValue % 1) * math.pow(10, decimalPlaces)).floor());
            newValue = maxValue;
          }
        }
        onChanged(newValue);
      }
    }
    return true;
  }

  bool _onDecimalNotification(Notification notification) {
    if (notification is ScrollNotification) {
      //calculate middle value
      int indexOfMiddleElement =
          (notification.metrics.pixels + _listViewHeight / 2) ~/ itemExtent;

      // FIXME: Handle values out of range.
      if (indexOfMiddleElement < _decimalValues.length) {
        int decimalValueInTheMiddle = _decimalValueFromIndex(
            indexOfMiddleElement);
        decimalValueInTheMiddle =
            _normalizeDecimalMiddleValue(decimalValueInTheMiddle);

        if (_userStoppedScrolling(notification, decimalScrollController)) {
          //center selected value
          animateDecimal(decimalValueInTheMiddle - 1);
          //update selection
          if (selectedIntValue != maxValue &&
              decimalValueInTheMiddle != selectedDecimalValue) {
            double decimalPart = _toDecimal(decimalValueInTheMiddle);
            double newValue = ((selectedIntValue + decimalPart).toDouble());
            _initDecimalValues(newValue);
            onChanged(newValue);
          }
        }

      }
    }
    return true;
  }

  ///There was a bug, when if there was small integer range, e.g. from 1 to 5,
  ///When user scrolled to the top, whole listview got displayed.
  ///To prevent this we are calculating cacheExtent by our own so it gets smaller if number of items is smaller
  double _calculateCacheExtent(int itemCount) {
    double cacheExtent = 250.0; //default cache extent
    if ((itemCount - 2) * DEFAULT_ITEM_EXTENT <= cacheExtent) {
      cacheExtent = ((itemCount - 3) * DEFAULT_ITEM_EXTENT);
    }
    return cacheExtent;
  }

  ///When overscroll occurs on iOS,
  ///we can end up with value not in the range between [minValue] and [maxValue]
  ///To avoid going out of range, we change values out of range to border values.
  int _normalizeMiddleValue(int valueInTheMiddle, int min, int max) {
    return math.max(math.min(valueInTheMiddle, max), min);
  }

  int _normalizeIntegerMiddleValue(int integerValueInTheMiddle) {
    //make sure that max is a multiple of step
    int max = (maxValue ~/ step) * step;
    return _normalizeMiddleValue(integerValueInTheMiddle, minValue.floor(), max);
  }

  int _normalizeDecimalMiddleValue(int decimalValueInTheMiddle) {
    return _normalizeMiddleValue(
        decimalValueInTheMiddle, 0, math.pow(10, decimalPlaces) - 1);
  }

  ///indicates if user has stopped scrolling so we can center value in the middle
  bool _userStoppedScrolling(Notification notification,
      ScrollController scrollController) {
    return notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle &&
        scrollController.position.activity is! HoldScrollActivity;
  }

  ///converts integer indicator of decimal value to double
  ///e.g. decimalPlaces = 1, value = 4  >>> result = 0.4
  ///     decimalPlaces = 2, value = 12 >>> result = 0.12
  double _toDecimal(int decimalValueAsInteger) {
    return double.parse((decimalValueAsInteger * math.pow(10, -decimalPlaces))
        .toStringAsFixed(decimalPlaces));
  }

  ///scroll to selected value
  _animate(ScrollController scrollController, double value) {
    scrollController.animateTo(value,
        duration: new Duration(seconds: 1), curve: new ElasticOutCurve());
  }
}

///Returns AlertDialog as a Widget so it is designed to be used in showDialog method
class NumberPickerDialog extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final int initialIntegerValue;
  final double initialDoubleValue;
  final int decimalPlaces;
  final Widget title;
  final EdgeInsets titlePadding;
  final Widget confirmWidget;
  final Widget cancelWidget;
  final int step;
  final bool infiniteLoop;

  ///constructor for integer values
  NumberPickerDialog.integer({
    @required this.minValue,
    @required this.maxValue,
    @required this.initialIntegerValue,
    this.title,
    this.titlePadding,
    this.step = 1,
    this.infiniteLoop = false,
    Widget confirmWidget,
    Widget cancelWidget,
  })
      : confirmWidget = confirmWidget ?? new Text("OK"),
        cancelWidget = cancelWidget ?? new Text("CANCEL"),
        decimalPlaces = 0,
        initialDoubleValue = -1.0;

  ///constructor for decimal values
  NumberPickerDialog.decimal({
    @required this.minValue,
    @required this.maxValue,
    @required this.initialDoubleValue,
    this.decimalPlaces = 1,
    this.title,
    this.titlePadding,
    Widget confirmWidget,
    Widget cancelWidget,
  })
      : confirmWidget = confirmWidget ?? new Text("OK"),
        cancelWidget = cancelWidget ?? new Text("CANCEL"),
        initialIntegerValue = -1,
        step = 1,
        infiniteLoop = false;

  @override
  State<NumberPickerDialog> createState() =>
      new _NumberPickerDialogControllerState(
          initialIntegerValue, initialDoubleValue);
}

class _NumberPickerDialogControllerState extends State<NumberPickerDialog> {
  int selectedIntValue;
  double selectedDoubleValue;

  _NumberPickerDialogControllerState(this.selectedIntValue,
      this.selectedDoubleValue);

  _handleValueChanged(num value) {
    if (value is int) {
      setState(() => selectedIntValue = value);
    } else {
      setState(() => selectedDoubleValue = value);
    }
  }

  NumberPicker _buildNumberPicker() {
    if (widget.decimalPlaces > 0) {
      return new NumberPicker.decimal(
          initialValue: selectedDoubleValue,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
          decimalPlaces: widget.decimalPlaces,
          onChanged: _handleValueChanged);
    } else {
      return new NumberPicker.integer(
        initialValue: selectedIntValue,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        step: widget.step,
        infiniteLoop: widget.infiniteLoop,
        onChanged: _handleValueChanged,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: widget.title,
      titlePadding: widget.titlePadding,
      content: _buildNumberPicker(),
      actions: [
        new FlatButton(
          onPressed: () => Navigator.of(context).pop(),
          child: widget.cancelWidget,
        ),
        new FlatButton(
            onPressed: () =>
                Navigator.of(context).pop(widget.decimalPlaces > 0
                    ? selectedDoubleValue
                    : selectedIntValue),
            child: widget.confirmWidget),
      ],
    );
  }
}
