import worker from '@ohos.worker';

let parent = worker.workerPort;

parent.onmessage = async function(message) {
  let index:number = message.data[2];
  const sharedArrayBuffer = message.data[1];
  const suo = message.data[0];
  const suoList = new Int8Array(suo);
  const sharedArray = new Int32Array(sharedArrayBuffer);
  while(true){
    let lockState:number=0;
    do {
      lockState = Atomics.exchange(suoList, 0, 0);
    } while (lockState !== 1);
    sale();
    // await pauseFor10ms();
  }
  function sale():void{
      if(sharedArray[0]>0){
        sharedArray[0]--;
        for(let i : number = 0;i<1000000;i++);
        console.log(index+'线程完成', sharedArray[0]);
      }
      Atomics.exchange(suoList, 0, 1);
  }
}

function pauseFor10ms(): Promise<void> {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve();
    }, 10);
  });
}

function printArgs2(args: [SharedArrayBuffer, SharedArrayBuffer,Number]): void{
  const int32Array = new Int32Array(args[0]);
  const flag=new Int8Array(args[1]);
  let lockState:number=0;
  do {
    lockState = Atomics.exchange(flag, 0, 0);
  } while (lockState !== 1);
  for (let i: number = 0; i < 1000000; i++) {
    console.log(args[2]+ " fuck: " + i);
    int32Array[0] = int32Array[0] - 1;
    Atomics.exchange(flag, 0, 1);
    //unlock(args[1]);
  }
}

/* index
import worker from '@ohos.worker';

let suo: SharedArrayBuffer = new SharedArrayBuffer(1024);
const suoList = new Int8Array(suo);
suoList[0] = 1;

let wk1 = new worker.ThreadWorker("entry/ets/workers/worker.ts");
let wk2 = new worker.ThreadWorker("entry/ets/workers/worker.ts");
let wk3 = new worker.ThreadWorker("entry/ets/workers/worker.ts");
let wk4 = new worker.ThreadWorker("entry/ets/workers/worker.ts");

let sharedBuffer: SharedArrayBuffer = new SharedArrayBuffer(1024);
const sharedArray = new Int32Array(sharedBuffer);
sharedArray[0] = 100;
let sharedList = [suo, sharedBuffer, 1];
wk1.postMessage(sharedList);
sharedList = [suo, sharedBuffer, 2];
wk2.postMessage(sharedList);
sharedList = [suo, sharedBuffer, 3];
wk3.postMessage(sharedList);
sharedList = [suo, sharedBuffer, 4];
wk4.postMessage(sharedList);
 */
// @ts-ignore
// @Concurrent
// function buy(args :  any){
//   let a = args[0];
//   while(a[0]>0){
//     a[0]--;
//     console.log("fuck "+a[0]);
//   }
// }
//
// let sharedArrayBuffer = new SharedArrayBuffer(32)
// let sharedArray = new Int32Array(sharedArrayBuffer)
// sharedArray[0] = 100;
// let shared = [sharedArray];
// taskpool.execute(buy, shared);
// taskpool.execute(buy, shared);
// taskpool.execute(buy, shared);


import taskpool from '@ohos.taskpool'

function numberEncoder(n ?: number) : Float64Array{
  const buffer = new SharedArrayBuffer(8);
  const sharedArray = new Float64Array(buffer);
  sharedArray[0] = 0;
  if(n!==null){
    sharedArray[0] = n;
  }
  return sharedArray;
}

function booleanEncoder(b ?: boolean) : Uint8Array{
  const buffer = new SharedArrayBuffer(1);
  const sharedArray = new Uint8Array(buffer);
  sharedArray[0] = 0;
  if(b!==null){
    if(b === true){
      sharedArray[0] = 1;
    }
  }
  return sharedArray;
}

function stringEncoder(s ?: string) : Uint8Array {
  let long : number = 0;
  if(s!==null){
    long = s.length + 3;
  }
  else{
    long = 1024;
  }
  const buffer = new SharedArrayBuffer(long);
  const sharedArray = new Uint8Array(buffer);
  if(s!==null) {
    for(let i=0;i<s.length;i++){
      sharedArray[i] = s.charCodeAt(i);
    }
    sharedArray[s.length] = 0;
  }
  return sharedArray;
}

function booleanDecoder(sharedArray : Uint8Array){
  if(sharedArray[0]===0){
    return false;
  }
  return true;
}

function stringDecoder(sharedArray : Uint8Array) : string{
  let receivedString = "";
  for(let i = 0;i<sharedArray.length && sharedArray[i] !== 0;i++){
    receivedString += String.fromCharCode(sharedArray[i]);
  }
  return receivedString;
}

function getClass(inClass : any){
  if(typeof inClass === 'number'){
    return numberEncoder(inClass);
  }
  else if(typeof inClass === 'boolean'){
    return booleanEncoder(inClass);
  }
  else if(typeof inClass === 'string') {
    return stringEncoder(inClass);
  }
  else{
    const members = Object.getOwnPropertyNames(inClass);
    let result = {};
    for(let i :number = 0;i<members.length;i++){
      if(typeof members[i]!=='function'){
        result[members[i]] = getClass(inClass[members[i]]);
      }
    }
    return result;
  }
}

class MyClass {
  public name: string;
  public  age: number;
  public email: string;

  constructor(name: string, age: number, email: string) {
    this.name = name;
    this.age = age;
    this.email = email;
  }
}


// @ts-ignore
@Concurrent
function test(args){
  let age = args.age;
  let name = args.name;
  let email = args.email;
  while(age[0]>0){
    for(let i:number=0;i<1000000;i++);
    age[0]--;
    console.log(stringDecoder(name)+' '+stringDecoder(email)+' '+age[0])
  }
}

let myclass: MyClass = new MyClass("fuck", 100, "ler=001");
let buffers:any = getClass(myclass);
taskpool.execute(test, buffers);
taskpool.execute(test, buffers);
taskpool.execute(test, buffers);
taskpool.execute(test, buffers);