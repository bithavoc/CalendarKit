import UIKit
import CalendarKit
import DateToolsSwift

class CustomCalendarExampleController: DayViewController, DatePickerControllerDelegate {

  var data = [["Breakfast at Tiffany's",
               "New York, 5th avenue"],

              ["Workout",
               "Tufteparken"],

              ["Meeting with Alex",
               "Home",
               "Oslo, Tjuvholmen"],

              ["Beach Volleyball",
               "Ipanema Beach",
               "Rio De Janeiro"],

              ["WWDC",
               "Moscone West Convention Center",
               "747 Howard St"],

              ["Google I/O",
               "Shoreline Amphitheatre",
               "One Amphitheatre Parkway"],

              ["✈️️ to Svalbard ❄️️❄️️❄️️❤️️",
               "Oslo Gardermoen"],

              ["💻📲 Developing CalendarKit",
               "🌍 Worldwide"],

              ["Software Development Lecture",
               "Mikpoli MB310",
               "Craig Federighi"],

              ]

  var generatedEvents = [Date:[MyEvent]]()

  var colors = [UIColor.blue,
                UIColor.yellow,
                UIColor.green,
                UIColor.red]

  var currentStyle = SelectedStyle.Light

  override func loadView() {
    calendar = Calendar.autoupdatingCurrent
    dayView = DayView(calendar: calendar)
    let style = CalendarStyle()
    style.timeline.dateStyle = .twelveHour
    dayView.updateStyle(style)
    view = dayView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Hitcal Playground"
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Dark",
                                                        style: .done,
                                                        target: self,
                                                        action: #selector(ExampleController.changeStyle))
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Change Date",
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(ExampleController.presentDatePicker))
    navigationController?.navigationBar.isTranslucent = false
    dayView.autoScrollToFirstEvent = true
    reloadData()
  }

  @objc func changeStyle() {
    var title: String!
    var style: CalendarStyle!

    if currentStyle == .Dark {
      currentStyle = .Light
      title = "Dark"
      style = StyleGenerator.defaultStyle()
    } else {
      title = "Light"
      style = StyleGenerator.darkStyle()
      currentStyle = .Dark
    }
    updateStyle(style)
    navigationItem.rightBarButtonItem!.title = title
    navigationController?.navigationBar.barTintColor = style.header.backgroundColor
    navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:style.header.swipeLabel.textColor]
    reloadData()
  }

  @objc func presentDatePicker() {
    let picker = DatePickerController()
    //    let calendar = dayView.calendar
    //    picker.calendar = calendar
    //    picker.date = dayView.state!.selectedDate
    picker.datePicker.timeZone = TimeZone(secondsFromGMT: 0)!
    picker.delegate = self
    let navC = UINavigationController(rootViewController: picker)
    navigationController?.present(navC, animated: true, completion: nil)
  }

  func datePicker(controller: DatePickerController, didSelect date: Date?) {
    if let date = date {
      var utcCalendar = Calendar(identifier: .gregorian)
      utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

      let offsetDate = dateOnly(date: date, calendar: dayView.calendar)

      print(offsetDate)
      dayView.state?.move(to: offsetDate)
    }
    controller.dismiss(animated: true, completion: nil)
  }

  func dateOnly(date: Date, calendar: Calendar) -> Date {
    let yearComponent = calendar.component(.year, from: date)
    let monthComponent = calendar.component(.month, from: date)
    let dayComponent = calendar.component(.day, from: date)
    let zone = calendar.timeZone

    let newComponents = DateComponents(timeZone: zone,
                                       year: yearComponent,
                                       month: monthComponent,
                                       day: dayComponent)
    let returnValue = calendar.date(from: newComponents)

    //    let returnValue = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date)


    return returnValue!
  }

  // MARK: EventDataSource
  
  var currentDate: Date?

  override func eventsForDate(_ date: Date) -> [EventDescriptor] {
    self.currentDate = date
    print("eventsForDate", date)
    var workingDate = date.add(TimeChunk.dateComponents(hours: Int(arc4random_uniform(10) + 5)))

    if let storedEvents = generatedEvents[date], !storedEvents.isEmpty {
      return storedEvents
    }

    var events = [MyEvent]()

    for i in 0...4 {
      let event = MyEvent()
      let duration = Int(arc4random_uniform(160) + 60)
      let datePeriod = TimePeriod(beginning: workingDate,
                                  chunk: TimeChunk.dateComponents(minutes: duration))

      event.startDate = datePeriod.beginning!
      event.endDate = datePeriod.end!

      var info = data[Int(arc4random_uniform(UInt32(data.count)))]

      let timezone = dayView.calendar.timeZone
      print(timezone)
      info.append(datePeriod.beginning!.format(with: "dd.MM.YYYY", timeZone: timezone))
      info.append("\(datePeriod.beginning!.format(with: "HH:mm", timeZone: timezone)) - \(datePeriod.end!.format(with: "HH:mm", timeZone: timezone))")
      event.text = info.reduce("", {$0 + $1 + "\n"})
      event.color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
      event.isAllDay = Int(arc4random_uniform(2)) % 2 == 0

      // Event styles are updated independently from CalendarStyle
      // hence the need to specify exact colors in case of Dark style
      if currentStyle == .Dark {
        event.textColor = textColorForEventInDarkTheme(baseColor: event.color)
        event.backgroundColor = event.color.withAlphaComponent(0.6)
      }

      events.append(event)

      let nextOffset = Int(arc4random_uniform(250) + 40)
      workingDate = workingDate.add(TimeChunk.dateComponents(minutes: nextOffset))
      event.userInfo = String(i)
    }

    generatedEvents[date] = events

    print("Events for \(date)")

    return events
  }

  private func textColorForEventInDarkTheme(baseColor: UIColor) -> UIColor {
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    baseColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return UIColor(hue: h, saturation: s * 0.3, brightness: b, alpha: a)
  }

  // MARK: DayViewDelegate

  override func dayViewDidSelectEventView(_ eventView: EventView) {
    guard let descriptor = eventView.descriptor as? MyEvent else {
      return
    }
    print("Event has been selected: \(descriptor.id) \(String(describing: descriptor.userInfo))")
    
    var events = generatedEvents[currentDate!]!
    print("before remove count", events.count)
    events.removeAll { return $0 == descriptor }
    print("after remove count", events.count)
    generatedEvents[currentDate!] = events
    dayView.reloadData()
  }

  override func dayViewDidLongPressEventView(_ eventView: EventView) {
    guard let descriptor = eventView.descriptor as? Event else {
      return
    }

    print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    dayView.beginEditing(event: descriptor, animated: true)
    print(Date())
  }

  override func dayView(dayView: DayView, didTapTimelineAt date: Date) {
    dayView.cancelPendingEventCreation()
    dayView.reloadData()
    self.createSampleEvent(at: date)
  }

  override func dayView(dayView: DayView, willMoveTo date: Date) {
    print("DayView = \(dayView) will move to: \(date)")
  }

  override func dayView(dayView: DayView, didMoveTo date: Date) {
    print("DayView = \(dayView) did move to: \(date)")
  }
  
  func createSampleEvent(at date: Date) {
    let duration = Int(60)
    
    let datePeriod = getDateInterval(date:date, duration: duration)
    print("Did Tap selected date \(date) for period \(datePeriod.beginning?.debugDescription ?? "") to \(datePeriod.end?.debugDescription ?? "")")
    
    dayView.cancelPendingEventCreation()
    let event = MyEvent()
      // let duration = Int(arc4random_uniform(160) + 60)
    event.startDate = datePeriod.beginning!
    event.endDate = datePeriod.end!

    var info = data[Int(arc4random_uniform(UInt32(data.count)))]
    let timezone = dayView.calendar.timeZone
    info.append(datePeriod.beginning!.format(with: "dd.MM.YYYY", timeZone: timezone))
    info.append("\(datePeriod.beginning!.format(with: "HH:mm", timeZone: timezone)) - \(datePeriod.end!.format(with: "HH:mm", timeZone: timezone))")
    event.text = info.reduce("", {$0 + $1 + "\n"})
    event.color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
    // event.editedEvent = event

    // Event styles are updated independently from CalendarStyle
    // hence the need to specify exact colors in case of Dark style
    if currentStyle == .Dark {
      event.textColor = textColorForEventInDarkTheme(baseColor: event.color)
      event.backgroundColor = event.color.withAlphaComponent(0.6)
    }
    print("Creating a new event")
    // dayView.create(event: event, animated: true)
    // event.commitEditing()
    
    
    var events = generatedEvents[currentDate!]!
    
    if !events.contains(event) {
      events.append(event)
    }
    generatedEvents[currentDate!] = events
    dayView.reloadData()
  }

  override func dayView(dayView: DayView, didLongPressTimelineAt date: Date) {
    print("Did long press timeline at date \(date)", date)
    self.createSampleEvent(at: date)
  }

  override func dayView(dayView: DayView, didUpdate event: EventDescriptor) {
    print("did finish editing \(event)")
    print("new startDate: \(event.startDate) new endDate: \(event.endDate)")
    if let _ = event.editedEvent {
      event.commitEditing()
    }
    dayView.cancelPendingEventCreation()
    dayView.reloadData()
  }
  private func component(component: Calendar.Component, from date: Date) -> Int {
    return calendar.component(component, from: date)
  }
  private func getDateInterval(date: Date, duration: Int) -> TimePeriod {
    let earliestEventMintues = component(component: .minute, from: date)
    let splitMinuteInterval = 30
    let minute = component(component: .minute, from: date)
    let minuteRange = (minute / splitMinuteInterval) * splitMinuteInterval
    let beginningRange = calendar.date(byAdding: .minute, value: -(earliestEventMintues - minuteRange), to: date)!
    let endRange = calendar.date(byAdding: .minute, value: duration, to: beginningRange)
    return TimePeriod.init(beginning: beginningRange, end: endRange)
  }
}

class MyEvent: Event {
  var id = UUID().uuidString
  override func makeEditable() -> Self {
    let editable = super.makeEditable() as! Self
    editable.id = id
    return editable
  }
}

extension MyEvent: Equatable {
  static func == (lhs: MyEvent, rhs: MyEvent) -> Bool {
    return lhs.id == rhs.id
  }
}
