class Test {
  private a: number = 1;

  public Inner = class {
    private b: number = 2;

    constructor(private outer: Test) {}

    public sum(): number {
      return this.outer.a + this.b;
    }
  }
}

class Run {
  public run(): void {
    let test: Test = new Test();
    let inner = new test.Inner(test);
    let b: number = inner.sum();
  }
}