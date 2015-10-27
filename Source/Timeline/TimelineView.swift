import UIKit
import Neon
import DateTools

class TimelineView: UIView {

  var date = NSDate() {
    didSet {
      label.text = date.formattedDateWithFormat("hh:mm")
      setNeedsDisplay()
    }
  }

  var eventViews = [EventView]() {
    willSet(newViews) {
      eventViews.forEach {$0.removeFromSuperview()}
    }

    didSet {
      setNeedsDisplay()
      eventViews.forEach {addSubview($0)}
    }
  }

  private var _eventHolder = [EventView]()

  //IFDEF DEBUG

  lazy var label = UILabel()

  lazy var nowLine: CurrentTimeIndicator = CurrentTimeIndicator()

  var hourColor = UIColor.lightGrayColor()
  var timeColor = UIColor.lightGrayColor()
  var lineColor = UIColor.lightGrayColor()

  var timeFont: UIFont {
    return UIFont.boldSystemFontOfSize(fontSize)
  }

  var verticalDiff: CGFloat = 45
  var verticalInset: CGFloat = 10
  var leftInset: CGFloat = 53

  var horizontalEventInset: CGFloat = 3

  var fullHeight: CGFloat {
    return verticalInset * 2 + verticalDiff * 24
  }

  var fontSize: CGFloat = 11

  var is24hClock = true {
    didSet {
      setNeedsDisplay()
    }
  }

  init() {
    super.init(frame: CGRect.zero)
    frame.size.height = fullHeight
    configure()
  }

  var times: [String] {
    return is24hClock ? _24hTimes : _12hTimes
  }

  private lazy var _12hTimes: [String] = Generator.timeStrings12H()
  private lazy var _24hTimes: [String] = Generator.timeStrings24H()

  var isToday: Bool {
    //TODO: Check for performance on device
    return date.isToday()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configure()
  }

  func configure() {
    contentScaleFactor = 1
    layer.contentsScale = 1
    contentMode = UIViewContentMode.Redraw
    backgroundColor = .whiteColor()
    addSubview(nowLine)
    addSubview(label)
  }

  override func drawRect(rect: CGRect) {
    super.drawRect(rect)

    var hourToRemoveIndex = -1

    if isToday {
      let today = NSDate()
      let minute = today.minute()
      if minute > 39 {
        hourToRemoveIndex = today.hour() + 1
      } else if minute < 21 {
        hourToRemoveIndex = today.hour()
      }
    }

    let style = NSParagraphStyle.defaultParagraphStyle().mutableCopy()
      as! NSMutableParagraphStyle

    style.lineBreakMode = .ByWordWrapping
    style.alignment = .Right
    let attributes = [NSParagraphStyleAttributeName: style,
      NSForegroundColorAttributeName: timeColor,
      NSFontAttributeName: timeFont]

    for (i, time) in times.enumerate() {
      let iFloat = CGFloat(i)
      let context = UIGraphicsGetCurrentContext()
      CGContextSetInterpolationQuality(context, .None)
      CGContextSaveGState(context)
      CGContextSetStrokeColorWithColor(context, lineColor.CGColor)
      CGContextSetLineWidth(context, onePixel)
      CGContextTranslateCTM(context, 0, 0.5)
      let x: CGFloat = 53
      let y = verticalInset + iFloat * verticalDiff
      CGContextBeginPath(context)
      CGContextMoveToPoint(context, x, y)
      CGContextAddLineToPoint(context, CGRectGetWidth(bounds), y)
      CGContextStrokePath(context)
      CGContextRestoreGState(context)

      if i == hourToRemoveIndex { continue }

      let timeRect = CGRect(x: 2, y: iFloat * verticalDiff + verticalInset - 7,
        width: leftInset - 8, height: fontSize + 2)

      let timeString = NSString(string: time)

      timeString.drawInRect(timeRect, withAttributes: attributes)
    }
  }

  override func layoutSubviews() {
    //TODO: Remove this label. Shows current day for testing purposes
    label.sizeToFit()
    label.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 375, height: 50))

    let size = CGSize(width: bounds.size.width, height: 20)
    let rect = CGRect(origin: CGPoint.zero, size: size)
    nowLine.date = date
    nowLine.frame = rect
    nowLine.center.y = dateToY(date)
    relayoutEvents()
  }

  func relayoutEvents() {
    if eventViews.isEmpty {return}

    let day = DTTimePeriod(size: .Day, startingAt:date)

    _eventHolder = eventViews.filter {$0.datePeriod.overlapsWith(day)}
      .sort {$0.datePeriod.StartDate.isEarlierThan($1.datePeriod.StartDate)}

    let datePeriods = _eventHolder.map {$0.datePeriod}
    let zipped = Array(Zip2Sequence(datePeriods, _eventHolder))

    var result = [[(DTTimePeriod, EventView)]]()
    var temporaryArray = [(DTTimePeriod, EventView)]()

    for tuple in zipped {
      if temporaryArray.isEmpty {
        temporaryArray.append(tuple)
        continue
      }

      if temporaryArray.last!.0.overlapsWith(tuple.0) {
        temporaryArray.append(tuple)
      } else {
        result.append(temporaryArray)
        temporaryArray.removeAll()
      }
    }

    let calendarWidth = bounds.width - leftInset

    for overlappingViews in result {
      let totalCount = CGFloat(overlappingViews.count)
      let events = overlappingViews.map {$0.1}
      for (index, event) in events.enumerate() {
        let startY = dateToY(event.datePeriod.StartDate)
        let endY = dateToY(event.datePeriod.EndDate)

        //TODO: Swift math
        let floatIndex = CGFloat(index)
        let x = leftInset + floatIndex / totalCount * calendarWidth

        let equalWidth = calendarWidth / totalCount

        event.frame = CGRect(x: x, y: startY, width: equalWidth, height: endY - startY)
      }
    }
  }

  func eventSafeZone(event: EventView) -> CGFloat {
    return event.frame.origin.y + event.contentHeight
  }

  // MARK: - Helpers

  private var onePixel: CGFloat {
    return 1 / UIScreen.mainScreen().scale
  }

  private func dateToY(date: NSDate) -> CGFloat {
    let hourY = CGFloat(date.hour()) * verticalDiff + verticalInset
    let minuteY = CGFloat(date.minute()) * verticalDiff / 60
    return hourY + minuteY
  }
}
