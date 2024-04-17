import { Thread, Runnable, getValues, blockSycStart, blockSycEnd, functionSycStart, functionSycEnd } from './ThreadBridge';

class TestThread {

  private tickets: number = 10000;
  public myTask: Function = TestThread;

  public run(): void {
    while (true) {
      this.sale();
    }
  }

  public sale(): void {
    if (this.tickets > 0) {
      if (this.tickets % 100 === 0) {
        console.log("is selling ticket " + this.tickets);
      }
      this.tickets--;
    }
  }

  public sum(a: number, b: number): number {
    return a + b;
  }
}

class Syn {

  public static main(args: string[]) {
    let tt: TestThread = new TestThread();
    new Thread(tt).start();
    new Thread(tt).start();
    new Thread(tt).start();
    new Thread(tt).start();
  }
}

// @Concurrent
function TicketSeller_Task(blockArray: Int8Array, funcArray: Int8Array, sharedArgs: any) {

  let tickets = sharedArgs.tickets;

  function run(): void {
    while (true) {
      sale();
    }
  }

  function sale(): void {
    functionSycStart(1, funcArray);
    if (getValues(tickets)[0] > 0) {
      if (getValues(tickets)[0] % 100 === 0) {
        console.log("is sailing ticket" + getValues(tickets)[0]);
      }
      tickets--;
    }
    functionSycEnd(1, funcArray);
  }

  function sum(a: number, b: number): number {
    return a + b;
  }

  run();
}

Syn.main(['']);

@Entry
@Component
struct Index {
  @State message: string = 'Hello World'

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {

          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
