import 'package:flutter/material.dart';
import 'package:habits_plus/localization.dart';
import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:date_utils/date_utils.dart';

class CalendarDetailWidget extends StatefulWidget {
  List<DateTime> progress;

  CalendarDetailWidget(this.progress);

  @override
  _CalendarDetailWidgetState createState() => _CalendarDetailWidgetState();
}

class _CalendarDetailWidgetState extends State<CalendarDetailWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 1,
        ),
      ),
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(10),
      child: _Calendar(
        selection: widget.progress.cast<DateTime>(),
      ),
    );
  }
}

typedef DayBuilder(BuildContext context, DateTime day);

class _Calendar extends StatefulWidget {
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<Tuple2<DateTime, DateTime>> onSelectedRangeChange;
  final bool isExpandable;
  final DayBuilder dayBuilder;
  final bool showChevronsToChangeRange;
  final bool showTodayAction;
  final bool showCalendarPickerIcon;
  final DateTime initialCalendarDateOverride;

  List<DateTime> selection;

  _Calendar({
    this.onDateSelected,
    this.onSelectedRangeChange,
    this.isExpandable: false,
    this.dayBuilder,
    this.showTodayAction: true,
    this.showChevronsToChangeRange: true,
    this.showCalendarPickerIcon: true,
    this.initialCalendarDateOverride,
    this.selection,
  });

  @override
  __CalendarState createState() => __CalendarState();
}

class __CalendarState extends State<_Calendar> {
  final calendarUtils = Utils();
  List<DateTime> selectedMonthsDays;
  Iterable<DateTime> selectedWeeksDays;
  DateTime _selectedDate = DateTime.now();
  String currentMonth;
  bool isExpanded = true;
  String displayMonth;
  DateTime get selectedDate => _selectedDate;

  // Selection
  List<DateTime> _leftSide = [];
  List<DateTime> _rightSide = [];
  List<DateTime> _middleSide = [];

  void initState() {
    super.initState();
    if (widget.initialCalendarDateOverride != null)
      _selectedDate = widget.initialCalendarDateOverride;
    selectedMonthsDays = Utils.daysInMonth(_selectedDate);
    var firstDayOfCurrentWeek = Utils.firstDayOfWeek(_selectedDate);
    var lastDayOfCurrentWeek = Utils.lastDayOfWeek(_selectedDate);
    selectedWeeksDays =
        Utils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
            .toList()
            .sublist(0, 7);

    // Init sides
    widget.selection.forEach((DateTime _date) {
      if (!widget.selection.contains(_date.subtract(Duration(days: 1)))) {
        _leftSide.add(_date);
        if (!widget.selection.contains(_date.add(Duration(days: 1)))) {
          _rightSide.add(_date);
        }
      } else if (!widget.selection.contains(_date.add(Duration(days: 1)))) {
        _rightSide.add(_date);
      } else {
        _middleSide.add(_date);
      }
    });
  }

  Widget get nameAndIconRow {
    var leftOuterIcon;
    var rightOuterIcon;

    if (widget.showChevronsToChangeRange) {
      leftOuterIcon = IconButton(
        onPressed: isExpanded ? previousMonth : previousWeek,
        icon: Icon(Icons.chevron_left),
      );
      rightOuterIcon = IconButton(
        onPressed: isExpanded ? nextMonth : nextWeek,
        icon: Icon(Icons.chevron_right),
      );
    } else {
      leftOuterIcon = Container();
      rightOuterIcon = Container();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        leftOuterIcon ?? Container(),
        // leftInnerIcon ??  Container(),
        Text(
          displayMonth,
          style: TextStyle(
            fontSize: 16.0,
          ),
        ),
        // rightInnerIcon ??  Container(),
        rightOuterIcon ?? Container(),
      ],
    );
  }

  Widget get calendarGridView {
    return Container(
      child: GestureDetector(
        onHorizontalDragStart: (gestureDetails) => beginSwipe(gestureDetails),
        onHorizontalDragUpdate: (gestureDetails) =>
            getDirection(gestureDetails),
        onHorizontalDragEnd: (gestureDetails) => endSwipe(gestureDetails),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          children: calendarBuilder(),
        ),
      ),
    );
  }

  List<Widget> calendarBuilder() {
    List<Widget> dayWidgets = [];
    List<DateTime> calendarDays = selectedMonthsDays;

    Utils.weekdays.forEach(
      (day) {
        dayWidgets.add(
          CalendarTile(
            isDayOfWeek: true,
            dayOfWeek: day,
          ),
        );
      },
    );

    bool monthStarted = false;
    bool monthEnded = false;

    calendarDays.forEach(
      (day) {
        if (monthStarted && day.day == 01) {
          monthEnded = true;
        }

        if (Utils.isFirstDayOfMonth(day)) {
          monthStarted = true;
        }

        if (this.widget.dayBuilder != null) {
          dayWidgets.add(
            CalendarTile(
              child: this.widget.dayBuilder(context, day),
              date: day,
              onDateSelected: () => handleSelectedDateAndUserCallback(day),
              isLeft: _leftSide.contains(day),
              isRight: _rightSide.contains(day),
              isMiddle: _middleSide.contains(day),
            ),
          );
        } else {
          dayWidgets.add(
            CalendarTile(
              onDateSelected: () => handleSelectedDateAndUserCallback(day),
              date: day,
              dateStyles: configureDateStyle(monthStarted, monthEnded),
              isSelected: Utils.isSameDay(selectedDate, day),
              isLeft: _leftSide.contains(day),
              isRight: _rightSide.contains(day),
              isMiddle: _middleSide.contains(day),
            ),
          );
        }
      },
    );
    return dayWidgets;
  }

  TextStyle configureDateStyle(monthStarted, monthEnded) {
    TextStyle dateStyles;
    final TextStyle body1Style = Theme.of(context).textTheme.body1;

    if (isExpanded) {
      final TextStyle body1StyleDisabled = body1Style.copyWith(
          color: Color.fromARGB(
        100,
        body1Style.color.red,
        body1Style.color.green,
        body1Style.color.blue,
      ));

      dateStyles =
          monthStarted && !monthEnded ? body1Style : body1StyleDisabled;
    } else {
      dateStyles = body1Style;
    }
    return dateStyles;
  }

  @override
  Widget build(BuildContext context) {
    List _mothSplit = Utils.formatMonth(_selectedDate).split(' ');
    displayMonth = AppLocalizations.of(context).translate(_mothSplit[0]) +
        ' ${_mothSplit[1]}';
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          nameAndIconRow,
          ExpansionCrossFade(
            collapsed: calendarGridView,
            expanded: calendarGridView,
            isExpanded: isExpanded,
          ),
          // expansionButtonRow
        ],
      ),
    );
  }

  void resetToToday() {
    _selectedDate = DateTime.now();
    var firstDayOfCurrentWeek = Utils.firstDayOfWeek(_selectedDate);
    var lastDayOfCurrentWeek = Utils.lastDayOfWeek(_selectedDate);

    setState(() {
      selectedWeeksDays =
          Utils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList();
      selectedMonthsDays = Utils.daysInMonth(_selectedDate);
      displayMonth = Utils.formatMonth(_selectedDate);
    });

    _launchDateSelectionCallback(_selectedDate);
  }

  void nextMonth() {
    setState(() {
      _selectedDate = Utils.nextMonth(_selectedDate);
      var firstDateOfMonth = Utils.firstDayOfMonth(_selectedDate);
      var lastDateOfMonth = Utils.lastDayOfMonth(_selectedDate);
      updateSelectedRange(firstDateOfMonth, lastDateOfMonth);
      selectedMonthsDays = Utils.daysInMonth(_selectedDate);
      displayMonth = Utils.formatMonth(_selectedDate);
    });
  }

  void previousMonth() {
    setState(() {
      _selectedDate = Utils.previousMonth(_selectedDate);
      var firstDateOfMonth = Utils.firstDayOfMonth(_selectedDate);
      var lastDateOfMonth = Utils.lastDayOfMonth(_selectedDate);
      updateSelectedRange(firstDateOfMonth, lastDateOfMonth);
      selectedMonthsDays = Utils.daysInMonth(_selectedDate);
      displayMonth = Utils.formatMonth(_selectedDate);
    });
  }

  void nextWeek() {
    setState(() {
      _selectedDate = Utils.nextWeek(_selectedDate);
      var firstDayOfCurrentWeek = Utils.firstDayOfWeek(_selectedDate);
      var lastDayOfCurrentWeek = Utils.lastDayOfWeek(_selectedDate);
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
      selectedWeeksDays =
          Utils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList()
              .sublist(0, 7);
      displayMonth = Utils.formatMonth(_selectedDate);
    });
    _launchDateSelectionCallback(_selectedDate);
  }

  void previousWeek() {
    setState(() {
      _selectedDate = Utils.previousWeek(_selectedDate);
      var firstDayOfCurrentWeek = Utils.firstDayOfWeek(_selectedDate);
      var lastDayOfCurrentWeek = Utils.lastDayOfWeek(_selectedDate);
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
      selectedWeeksDays =
          Utils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList()
              .sublist(0, 7);
      displayMonth = Utils.formatMonth(_selectedDate);
    });
    _launchDateSelectionCallback(_selectedDate);
  }

  void updateSelectedRange(DateTime start, DateTime end) {
    var selectedRange = Tuple2<DateTime, DateTime>(start, end);
    if (widget.onSelectedRangeChange != null) {
      widget.onSelectedRangeChange(selectedRange);
    }
  }

  Future<Null> selectDateFromPicker() async {
    DateTime selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime(2050),
    );

    if (selected != null) {
      var firstDayOfCurrentWeek = Utils.firstDayOfWeek(selected);
      var lastDayOfCurrentWeek = Utils.lastDayOfWeek(selected);

      setState(() {
        _selectedDate = selected;
        selectedWeeksDays =
            Utils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
                .toList();
        selectedMonthsDays = Utils.daysInMonth(selected);
        displayMonth = Utils.formatMonth(selected);
      });
      // updating selected date range based on selected week
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
      _launchDateSelectionCallback(selected);
    }
  }

  var gestureStart;
  var gestureDirection;

  void beginSwipe(DragStartDetails gestureDetails) {
    gestureStart = gestureDetails.globalPosition.dx;
  }

  void getDirection(DragUpdateDetails gestureDetails) {
    if (gestureDetails.globalPosition.dx < gestureStart) {
      gestureDirection = 'rightToLeft';
    } else {
      gestureDirection = 'leftToRight';
    }
  }

  void endSwipe(DragEndDetails gestureDetails) {
    if (gestureDirection == 'rightToLeft') {
      if (isExpanded) {
        nextMonth();
      } else {
        nextWeek();
      }
    } else {
      if (isExpanded) {
        previousMonth();
      } else {
        previousWeek();
      }
    }
  }

  void toggleExpanded() {
    if (widget.isExpandable) {
      setState(() => isExpanded = !isExpanded);
    }
  }

  void handleSelectedDateAndUserCallback(DateTime day) {
    var firstDayOfCurrentWeek = Utils.firstDayOfWeek(day);
    var lastDayOfCurrentWeek = Utils.lastDayOfWeek(day);
    setState(() {
      _selectedDate = day;
      selectedWeeksDays =
          Utils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList();
      selectedMonthsDays = Utils.daysInMonth(day);
      displayMonth = Utils.formatMonth(_selectedDate);
    });
    _launchDateSelectionCallback(day);
  }

  void _launchDateSelectionCallback(DateTime day) {
    if (widget.onDateSelected != null) {
      widget.onDateSelected(day);
    }
  }
}

class ExpansionCrossFade extends StatelessWidget {
  final Widget collapsed;
  final Widget expanded;
  final bool isExpanded;

  ExpansionCrossFade({this.collapsed, this.expanded, this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      child: AnimatedCrossFade(
        firstChild: collapsed,
        secondChild: expanded,
        firstCurve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
        secondCurve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
        sizeCurve: Curves.decelerate,
        crossFadeState:
            isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class CalendarTile extends StatelessWidget {
  final VoidCallback onDateSelected;
  final DateTime date;
  final String dayOfWeek;
  final bool isDayOfWeek;
  final bool isSelected;
  final TextStyle dayOfWeekStyles;
  final TextStyle dateStyles;
  final Widget child;

  bool isLeft;
  bool isRight;
  bool isMiddle;

  CalendarTile({
    this.onDateSelected,
    this.date,
    this.child,
    this.dateStyles,
    this.dayOfWeek,
    this.dayOfWeekStyles,
    this.isDayOfWeek: false,
    this.isSelected: false,
    this.isLeft,
    this.isRight,
    this.isMiddle,
  });

  Widget renderDateOrDayOfWeek(BuildContext context) {
    if (isDayOfWeek) {
      return InkWell(
        child: Container(
          alignment: Alignment.center,
          child: Text(
            // dayOfWeek,
            AppLocalizations.of(context).translate(dayOfWeek),
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      return Container(
        child: InkWell(
          onTap: onDateSelected,
          child: Container(
            decoration: isLeft || isRight || isMiddle
                ? BoxDecoration(
                    borderRadius: isMiddle
                        ? BorderRadius.only(
                            topLeft: isLeft
                                ? Radius.circular(50)
                                : Radius.circular(0),
                            bottomLeft: isLeft
                                ? Radius.circular(50)
                                : Radius.circular(0),
                            topRight: isRight
                                ? Radius.circular(50)
                                : Radius.circular(0),
                            bottomRight: isRight
                                ? Radius.circular(50)
                                : Radius.circular(0),
                          )
                        : BorderRadius.circular(15),
                    color: isLeft || isRight
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                  )
                : BoxDecoration(),
            alignment: Alignment.center,
            child: Container(
              // width: isSelected && !isMiddle && !isRight && !isLeft
              //     ? 40
              //     : double.infinity,
              // height: 40,
              margin: EdgeInsets.symmetric(
                horizontal:
                    isSelected && !isMiddle && !isRight && !isLeft ? 5 : 0,
                vertical:
                    isMiddle || isRight || isLeft ? 5 : isSelected ? 5 : 0,
              ),
              decoration: isSelected && !isMiddle && !isRight && !isLeft
                  ? BoxDecoration(
                      color:
                          Theme.of(context).textSelectionColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : BoxDecoration(
                      borderRadius: isLeft || isRight
                          ? BorderRadius.only(
                              topLeft: isLeft
                                  ? Radius.circular(50)
                                  : Radius.circular(0),
                              bottomLeft: isLeft
                                  ? Radius.circular(50)
                                  : Radius.circular(0),
                              topRight: isRight
                                  ? Radius.circular(50)
                                  : Radius.circular(0),
                              bottomRight: isRight
                                  ? Radius.circular(50)
                                  : Radius.circular(0),
                            )
                          : null,
                      color: isLeft || isRight || isMiddle
                          ? Theme.of(context).primaryColor.withOpacity(0.6)
                          : Colors.transparent,
                    ),
              child: Center(
                child: Text(
                  Utils.formatDay(date).toString()[0] == '0'
                      ? Utils.formatDay(date).toString()[1]
                      : Utils.formatDay(date).toString(),
                  style: isSelected || isLeft || isRight || isMiddle
                      ? Theme.of(context).primaryTextTheme.body1
                      : dateStyles,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return InkWell(
        child: child,
        onTap: onDateSelected,
      );
    }
    return Container(
      child: renderDateOrDayOfWeek(context),
    );
  }
}
