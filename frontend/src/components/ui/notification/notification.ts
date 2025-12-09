import { getWidth, TOUCH_WIDTH } from "@/utils/browser"
import { computed, reactive, type ComputedRef } from "vue"

const TOP_INCREMENT = 5
const MIN_TIMEOUT_SECONDS = 3

export const notificationTypeClassMap = {
  DANGER: "bg-red-400",
  INFO: "bg-blue-400",
}

export type NotificationType = keyof typeof notificationTypeClassMap

type Top = {
  value: number
}

type Style = {
  top: string
}

export class NotificationItem {
  public timeoutSec: number
  public top: Top
  public style: ComputedRef<Style>
  public message: string
  public classes: string[]
  public styleString: ComputedRef<string>

  constructor(
    type: NotificationType,
    message: string,
    timeoutSec = MIN_TIMEOUT_SECONDS,
  ) {
    if (timeoutSec && timeoutSec < MIN_TIMEOUT_SECONDS) {
      throw `timeoutSec: !(${timeoutSec} >= ${MIN_TIMEOUT_SECONDS})`
    }

    const browserWidth = getWidth()

    this.timeoutSec = timeoutSec ? timeoutSec : MIN_TIMEOUT_SECONDS
    this.message = message
    this.classes = reactive([
      notificationTypeClassMap[type],
      browserWidth > TOUCH_WIDTH ? "desktop" : "mobile",
    ])

    this.top = reactive({ value: browserWidth > TOUCH_WIDTH ? 5 : 0 })

    this.style = computed(() => {
      return {
        top: `${this.top.value}rem`,
      }
    })

    this.styleString = computed(() => {
      return Object.entries(this.style.value)
        .map((item) => `${item[0]}: ${item[1]}`)
        .join(" ")
    })
  }

  activateFadeOut() {
    this.classes.push("fade-out")
  }
}

export class NotificationCollection {
  items: NotificationItem[] = []

  addItem(item: NotificationItem) {
    this.items.push(item)

    if (this.items.length > 1) {
      item.top.value =
        this.items[this.items.length - 2].top.value + TOP_INCREMENT
    }

    setTimeout(() => this.removeItem(), item.timeoutSec * 1000)
    setTimeout(() => item.activateFadeOut(), (item.timeoutSec - 0.5) * 1000)
  }

  removeItem() {
    this.items = this.items.slice(1, this.items.length)
    for (const item of this.items) {
      item.top.value -= TOP_INCREMENT
    }
  }
}

export const notificationCollection = reactive(new NotificationCollection())
