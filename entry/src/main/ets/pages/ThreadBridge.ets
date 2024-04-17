import taskpool from '@ohos.taskpool';

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

export function getValues(code: any){
  let type = code.sharedType;
  if(type === "number"){
    return code.sharedValue;
  }
  else if(type === "string"){
    return [stringDecoder(code.sharedValue)];
  }
  else if(type === "boolean"){
    return [booleanDecoder(code.sharedValue)];
  }
  else {
    return [code];
  }
}

function numberEncoder(n ?: number){
  const buffer = new SharedArrayBuffer(8);
  const sharedArray = new Float64Array(buffer);
  sharedArray[0] = 0;
  if(n!==null){
    sharedArray[0] = n;
  }
  return {"sharedValue": sharedArray, "sharedType": "number"};
}

function booleanEncoder(b ?: boolean){
  const buffer = new SharedArrayBuffer(1);
  const sharedArray = new Uint8Array(buffer);
  sharedArray[0] = 0;
  if(b!==null){
    if(b === true){
      sharedArray[0] = 1;
    }
  }
  return {"sharedValue": sharedArray, "sharedType": "boolean"};
}

function stringEncoder(s ?: string){
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
  return {"sharedValue": sharedArray, "sharedType": "string"};
}

export function getClass(inClass : any){
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
      if(typeof members[i]!=="function" && members[i]!=="runnableShared"){
        result[members[i]] = getClass(inClass[members[i]]);
      }
    }
    result["sharedType"] = "others";
    return result;
  }
}

export function getSyc(){
  let block = new SharedArrayBuffer(200);
  let blockArray = new Int8Array(block);
  for(let i=0;i<100;i++){
    blockArray[i] = 1;
  }
  let func = new SharedArrayBuffer(200);
  let funcArray = new Int8Array(func);
  for(let i=0;i<100;i++){
    funcArray[i] = 1;
  }
  return {"blockArray": blockArray, "funcArray": funcArray};
}

export interface Runnable{
  run(): void;
}

export class Thread{
  private runnableShared : any = null;
  private runnableFunc : Function = null;
  private runnableSyc: any = null;
  static runnableList  = [];

  static getThreadOwn(myClass : any) :  any{
    return myClass;
  }

  public getSelf() : any{
    if(this.runnableShared === null){
      let myClass = Thread.getThreadOwn(this);
      this.runnableFunc = myClass.myTask;
      this.runnableShared = getClass(myClass);
      this.runnableSyc = getSyc();
    }
  }

  public start(): void{
    if(this.runnableShared === null){
      this.getSelf();
    }
    taskpool.execute(this.runnableFunc, this.runnableSyc.blockArray, this.runnableSyc.funcArray, this.runnableShared);
  }

  constructor(runnable: any = null) {
    if(runnable !== null){
      if(this.runnableShared === null){
        for(let i = 0;i<Thread.runnableList.length;i++){
          if(Thread.runnableList[i].runnable === runnable){
            this.runnableShared = Thread.runnableList[i].runnableShared;
            this.runnableFunc = runnable.myTask;
            this.runnableSyc = Thread.runnableList[i].runnableSyc;
            break;
          }
        }
      }
      if(this.runnableShared === null){
        this.runnableShared = getClass(runnable);
        this.runnableFunc = runnable.myTask;
        this.runnableSyc = getSyc();
        Thread.runnableList.push({"runnable": runnable, "runnableShared": this.runnableShared, "runnableSyc": this.runnableSyc});
      }
    }
  }
}

export function blockSycStart(i : number, blockArray: Int8Array){
  let lockState:number=0;
  do {
    lockState = Atomics.exchange(blockArray, i, 0);
  } while (lockState !== 1);
}

export function functionSycStart(i : number, funcArray: Int8Array){
  let lockState:number=0;
  do {
    lockState = Atomics.exchange(funcArray, i, 0);
  } while (lockState !== 1);
}

export function blockSycEnd(i : number, blockArray: Int8Array){
  Atomics.exchange(blockArray, i, 1);
}

export function functionSycEnd(i : number, funcArray: Int8Array){
  Atomics.exchange(funcArray, i, 1);
}