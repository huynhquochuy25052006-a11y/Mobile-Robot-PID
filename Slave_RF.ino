//Slave K:
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>
#include <MPU6050_tockn.h>
#include <Wire.h>
#include <math.h>
#include <Preferences.h>

#define EncoderA1 35
#define EncoderB1 34
#define EncoderA2 17
#define EncoderB2 16
#define enA 32
#define in1 33
#define in2 25
#define enB 13
#define in3 26
#define in4 27
#define LED 14
#define Buzzer 12
#define SDA 21
#define SCL 22
#define CE_PIN 4
#define CSN_PIN 5

MPU6050 mpu6050(Wire);
RF24 RF(CE_PIN, CSN_PIN);
Preferences save;


const byte addressRx[6] = "NODE1"; // nhận từ A
const byte addressTx[6] = "NODE2"; // gửi phản hồi lại A

//Cấu hình mô hình---------------------------------
float R = 3.4;
float ig = 30.0; //Tỉ số truyền
float c = 4.0;
float L = 8.0;
//
float sampleTime = 0.02; // Thời gian lấy mẫu
// long waitTime2 = 1000;
signed int speed = 0;
bool running = false;
bool revCam = false;
int maxPWM = 255;
float preXCam, preYCam;
// float rps = 0;
// float w = 0;
// float v = 0;
float res = 4;
float tt1 = 0;
float xTest, yTest;
//Cấu hình mô hình---------------------------------

//Các đối tượng thời gian--------------------------
struct thoigian{
  double now = 0;
  double previous = 0;
  double previous1 = 0;
  float delta = 0;
  double timer = 0;
  bool stop;
};
thoigian velTime;
thoigian trajTime;
thoigian lineTime;
thoigian upTrajTimer;
thoigian upLoadTimer;
//Các đối tượng thời gian--------------------------

//Biến động học thuận------------------------------
float nowTime = 0, preTime = 0;
float nowX = 0, nowY = 0, nowPhi = 0;
float preX = 0, preY = 0, prePhi = 0;
//Biến động học thuận------------------------------

//Biến động học nghịch-----------------------------
float nowXTraj = 0, nowYTraj = 0;
float preXTraj = 0, preYTraj = 0;
float vXTraj = 0, vYTraj = 0;
float vRightTraj = 0, vLeftTraj = 0;
float lx = 22.0, ly = 18.0, kx = 1.0, ky = 1.0;
//Biến động học nghịch-----------------------------

//Biến---------------------------------------------
// unsigned long timeMillis;
int pointsNum = 0;
// bool startCal = false;
int i = 0, x = 0, y = 1;
double points[50][2];
double paintPoints[100][2];
unsigned long k = 0, paintNums = 0;
//Biến---------------------------------------------

struct Packet {
  uint8_t id;   // 1=traj, 2=LeftPID, 3=RightPID
  uint8_t data[30]; // phần dữ liệu (max 30 byte)
};
Packet pack;

void sendRF(uint8_t id, void* src, size_t size) {
  pack.id = id;
  memcpy(pack.data, src, size);
  RF.write(&pack, sizeof(pack));
}
// id=1
typedef struct MasterStarts{
  bool Stop;
  bool StartCircle;
  bool StartEight;
  bool StartP2P;
  bool StartPaint;
  bool EndPaint;
  bool EnORCam;
  bool StartCam;
}MasterStarts;
MasterStarts MasterStart;
// id=2
typedef struct trajdatas{
  float a;
  float b;
  float r;
  float vel;
  bool DownTrajData;
}trajdatas;
trajdatas trajdata;
// id=3
typedef struct LeftPIDs{
  float KpL;
  float KiL;
  float KdL;
  float NL;
  bool DownPIDData;
}LeftPIDs;
LeftPIDs LeftPID;
// id=4
typedef struct RightPIDs{
  float KpR;
  float KiR;
  float KdR;
  float NR;
  bool DownPIDData;
}RightPIDs;
RightPIDs RightPID;
// id=5
typedef struct drawTrajDatas{
  float xPoint;
  float yPoint;
  float xPaint;
  float yPaint;
}drawTrajDatas;
drawTrajDatas drawTrajData;
drawTrajDatas lastData;
// id=6
typedef struct SlaveDatas{
  float vRight;
  float vLeft;
  float x;
  float y;
  float vRightTraj;
  float vLeftTraj;
}SlaveDatas;
SlaveDatas SlaveData;
// id=7
typedef struct Cams{
  float xCam;
  float yCam;
  float pCam;
}Cams;
Cams Cam;
//Encoder------------------------------------------
volatile long enCount1 = 0;
void IRAM_ATTR readEncoderA1() {
  if (digitalRead(EncoderA1) == digitalRead(EncoderB1)) {
    enCount1++;
  } else {
    enCount1--;
  }
}

void IRAM_ATTR readEncoderB1() {
  if (digitalRead(EncoderA1) != digitalRead(EncoderB1)) {
    enCount1++;
  } else {
    enCount1--;
  }
}

volatile long enCount2 = 0;
void IRAM_ATTR readEncoderA2() {
  if (digitalRead(EncoderA2) == digitalRead(EncoderB2)) {
    enCount2++;
  } else {
    enCount2--;
  }
}

void IRAM_ATTR readEncoderB2() {
  if (digitalRead(EncoderA2) != digitalRead(EncoderB2)) {
    enCount2++;
  } else {
    enCount2--;
  }
}
//Encoder------------------------------------------

//PID Controller-----------------------------------
struct PID{
  float Kp = 0, Ki = 0, Kd = 0, N = 0;
  float P, I, D;
  float error, preError;
  float filterDstate = 0;

  float PIDCal(float Setpoint, float CurValue, float deltaT, float Kp, float Ki, float Kd, float N){
    float D_Kd;
    error = Setpoint - CurValue;
    P = error;
    I = I + error*deltaT;
    
    if(N == 0){
      D = (error - preError)/deltaT;
      preError = error;
      D_Kd = Kd*D; 
    }else{
      float filterD = (Kd*error - filterDstate)*N;
      filterDstate += deltaT*filterD;
      D_Kd = filterDstate;
    }
    return constrain(Kp*P+Ki*I+D_Kd,-250,250);
  }
  void resetPID(){
    P = 0;
    I = 0;
    D = 0;
    N = 0;
  }
};

struct PID RightMotor;
struct PID LeftMotor;
//PID Controller-----------------------------------

//Motor Data---------------------------------------
struct MotorData{
  float v = 0;
  float vPID = 0;
  float velCal(float enCount, float res, float ig, float R, float deltaT){
    float rps = ((enCount/(11.0*res))/ig)/deltaT;
    float w = rps*2.0*M_PI;
    float vMotor = w*R;
    return vMotor;    
  }
};

struct MotorData VelMotor;
struct MotorData MotorLeft;
struct MotorData MotorRight;

void motor1(int dir1, int dir2, int pwmA){
  digitalWrite(in1, dir1);
  digitalWrite(in2, dir2);
  analogWrite(enA, pwmA);
}

void motor2(int dir3, int dir4, int pwmB){
  digitalWrite(in3, dir3);
  digitalWrite(in4, dir4);
  analogWrite(enB, pwmB);
}
//Motor Data---------------------------------------

//Đọc dữ liệu MPU----------------------------------
void readMPU(){
  if(MasterStart.EnORCam == false){
    mpu6050.update();
    prePhi = nowPhi;
    nowPhi = (mpu6050.getAngleZ())*(M_PI/180.0);
  }else if(MasterStart.EnORCam == true){
    prePhi = nowPhi;
    nowPhi = Cam.pCam;
  }
}
//Đọc dữ liệu MPU----------------------------------

//Tính động học thuận------------------------------
void FWKematic(float vRight, float vLeft, float deltaT){
  float vModel = (vRight + vLeft)/2.0;
  float wModel = (vRight - vLeft)/(2.0*L);

  nowX = preX + (vModel*cos(nowPhi)-wModel*c*sin(nowPhi))*deltaT;
  nowY = preY + (vModel*sin(nowPhi)+wModel*c*cos(nowPhi))*deltaT;
  // nowPhi = prePhi + wModel*deltaT;

  preX = nowX;
  preY = nowY;
  // prePhi = nowPhi;
}
//Tính động học thuận------------------------------

//Tính động học nghịch-----------------------------
void IVKematic(float xTraj, float yTraj, float deltaT){
  nowXTraj = xTraj;
  nowYTraj = yTraj;

  vXTraj = (nowXTraj-preXTraj)/(deltaT);
  vYTraj = (nowYTraj-preYTraj)/(deltaT);

  // float velXMatrix = vXTraj + lx*tanh((kx/lx)*(nowXTraj-nowX));
  // float velYMatrix = vYTraj + ly*tanh((ky/ly)*(nowYTraj-nowY));

  float velXMatrix = vXTraj + (nowXTraj-nowX);
  float velYMatrix = vYTraj + (nowYTraj-nowY);

  preXTraj = nowXTraj;
  preYTraj = nowYTraj;

  float vModelTraj = velXMatrix*cos(nowPhi)+velYMatrix*sin(nowPhi);
  float wModelTraj = velXMatrix*(-1.0)*(sin(nowPhi)/c)+velYMatrix*(cos(nowPhi)/c);

  vRightTraj = vModelTraj+L*wModelTraj;
  vLeftTraj = vModelTraj-L*wModelTraj;
}
//Tính động học nghịch-----------------------------

//Chương trình quỹ đạo-----------------------------
struct trajectory{
  float xCir = 0;
  float yCir = 0;
  float xEig = 0;
  float yEig = 0;
  float xLine = 0;
  float yLine = 0;
  float xPaint = 0;
  float yPaint = 0;
  float r = 0;
  float a = 0;
  float b = 0;
  float v = 0;
  void circle(float radius, float vel, double t){
    float w = vel/radius;
    xCir = radius*cos(w*t);
    yCir = radius*sin(w*t);
    trajTime.timer += 0.02;
  }
  void eight(float a, float b, float w, double t){
    xEig = a*sin(w*t);
    yEig = (b/2.0)*sin(2*w*t);
    trajTime.timer += 0.02;
  }
  void p2p(float t1, float v){
    //Hệ số phương trình đường thẳng
    if(pointsNum < i-1){
      float x1 = points[pointsNum][x];
      float y1 = points[pointsNum][y];
      float x2 = points[pointsNum+1][x];
      float y2 = points[pointsNum+1][y];

      float s = sqrt(pow(x2-x1,2)+pow(y2-y1,2));
      float duration = s/v; // giây
      float t2 = t1 / duration;

      xLine = x1 + (x2 - x1)*t2;
      yLine = y1 + (y2 - y1)*t2;
      lineTime.timer+=0.02;
      if(t1 > duration){
        pointsNum++;
        lineTime.timer = 0;
      }
    }else{
      pointsNum = 0;
      i = 0;
      motor1(0,0,0);
      motor2(0,0,0);
      // return;
    }
  }
  void paint(float t1, float v){
    if(paintNums < k-1 && k!=0){
      float x1 = paintPoints[paintNums][x];
      float y1 = paintPoints[paintNums][y];
      float x2 = paintPoints[paintNums+1][x];
      float y2 = paintPoints[paintNums+1][y];

      float s = sqrt(pow(x2-x1,2)+pow(y2-y1,2));
      float duration = s/v; // giây
      float t2 = t1 / duration;

      xPaint = x1 + (x2 - x1)*t2;
      yPaint = y1 + (y2 - y1)*t2;
      lineTime.timer+=0.02;
      if(t1 > duration){
        paintNums++;
        lineTime.timer = 0;
      }
    }else{
      paintNums = 0;
      k = 0;
      motor1(0,0,0);
      motor2(0,0,0);
      // return;
    }
  }
};

struct trajectory traj;
//Chương trình quỹ đạo-----------------------------
void RunCircle(){
  traj.circle(traj.r, traj.v, trajTime.timer); //velTime.now
  IVKematic(traj.xCir,traj.yCir,velTime.delta);
}

void RunEight(){
  traj.eight(traj.a, traj.b, traj.v, trajTime.timer);
  IVKematic(traj.xEig,traj.yEig,velTime.delta);
}

void RunLine(){
  // trajTime.timer = 0;
  traj.p2p(lineTime.timer, traj.v);
  // Serial.printf("X: %.3f, Y: %.3f\n",traj.xLine,traj.yLine);
  IVKematic(traj.xLine,traj.yLine,velTime.delta);
}

void RunPaint(){
  traj.paint(lineTime.timer, traj.v);
  IVKematic(traj.xPaint,traj.yPaint,velTime.delta);
}

void updateTraj(){
  if(trajdata.DownTrajData == false){
    if(i == 0){
      points[i][x] = nowX;
      points[i][y] = nowY;
      i++;
    }else if(i > 0){
      if(drawTrajData.xPoint != lastData.xPoint || drawTrajData.yPoint != lastData.yPoint){
        // Serial.printf("X: %.3f, Y: %.3f\n",MasterData.xPoint,MasterData.yPoint);
        points[i][x] = drawTrajData.xPoint;
        points[i][y] = drawTrajData.yPoint;
        lastData.xPoint = drawTrajData.xPoint;
        lastData.yPoint = drawTrajData.yPoint;
        // Serial.printf("X[%d]: %.3f, Y[%d]: %.3f\n",i,points[i][x],i,points[i][y]);
        i++;
      }
    }
    lisRF();
  }
}

void updateData(){
  traj.r = trajdata.r;
  traj.a = trajdata.a;
  traj.b = trajdata.b;
  traj.v = trajdata.vel;

  RightMotor.Kp = RightPID.KpR;
  RightMotor.Ki = RightPID.KiR;
  RightMotor.Kd = RightPID.KdR;
  RightMotor.N = RightPID.NR;

  LeftMotor.Kp = LeftPID.KpL;
  LeftMotor.Ki = LeftPID.KiL;
  LeftMotor.Kd = LeftPID.KdL;
  LeftMotor.N = LeftPID.NL;
  
  digitalWrite(Buzzer,1); delay(200);
  digitalWrite(Buzzer,0); delay(200);
  digitalWrite(Buzzer,1); delay(200);
  digitalWrite(Buzzer,0); delay(200);
}

void lisRF(){
  RF.startListening();
  if(RF.available()){
    RF.read(&pack, sizeof(pack));
    switch(pack.id){
      case 7:
        memcpy(&Cam, pack.data, sizeof(Cam));
        // Serial.printf("x: %.3f,y: %.3f,phi: %.3f\n",Cam.xCam,Cam.yCam,Cam.pCam);
        break;
      case 1:
        memcpy(&MasterStart, pack.data, sizeof(MasterStart));
        // Serial.printf("%d,%d,%d,%d,%d\n",MasterStart.Stop,MasterStart.StartCircle,MasterStart.StartEight,MasterStart.StartP2P,MasterStart.StartPaint);
        if(MasterStart.Stop == true){
          motor1(0,0,0);
          motor2(0,0,0);
        }
        running = true;
        break;        
      case 2:
        memcpy(&trajdata, pack.data, sizeof(trajdata));
        // Serial.printf("%.3f,%.3f,%.3f,%.3f,%d\n",trajdata.a,trajdata.b,trajdata.r,trajdata.vel,trajdata.DownTrajData);
        running = false;
        break;
      case 3:
        memcpy(&LeftPID, pack.data, sizeof(LeftPID));
        // Serial.printf("%.3f,%.3f,%.3f,%.3f,%d\n",LeftPID.KpL,LeftPID.KiL,LeftPID.KdL,LeftPID.NL,LeftPID.DownPIDData);
        break;
      case 4:
        memcpy(&RightPID, pack.data, sizeof(RightPID));
        // Serial.printf("%.3f,%.3f,%.3f,%.3f,%d\n",RightPID.KpR,RightPID.KiR,RightPID.KdR,RightPID.NR,RightPID.DownPIDData);
        break;
      case 5:
        memcpy(&drawTrajData, pack.data, sizeof(drawTrajData));
        // Serial.printf("%.3f,%.3f,%.3f,%.3f\n",drawTrajData.xPoint,drawTrajData.yPoint,drawTrajData.xPaint,drawTrajData.yPaint);
        // Serial.printf("%.3f,%.3f\n",drawTrajData.xPaint,drawTrajData.yPaint);
        running = false;
        if(MasterStart.EndPaint == true){
          paintPoints[k][x] = drawTrajData.xPaint;
          paintPoints[k][y] = drawTrajData.yPaint;
        // Serial.printf("%d, %.2f, %.2f\n",k,paintPoints[k][x],paintPoints[k][y]);
          k++;
          motor1(0,0,0);
          motor2(0,0,0);
        // }else if(MasterStart.EndPaint == false){
        //   k = 0;
        }
        break;
    }
  }
}

void setup() {
  Serial.begin(9600);
  
  pinMode(enA, OUTPUT);
  pinMode(enB, OUTPUT);
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);
  pinMode(in3, OUTPUT);
  pinMode(in4, OUTPUT);
  analogWrite(enA,0);
  analogWrite(enB,0);
  digitalWrite(in1,0);
  digitalWrite(in2,0);
  digitalWrite(in3,0);
  digitalWrite(in4,0);
  digitalWrite(LED,0);
  digitalWrite(Buzzer,0);
  
  RF.begin();
  RF.setPALevel(RF24_PA_LOW);

  RF.openWritingPipe(addressTx);
  RF.openReadingPipe(1, addressRx);
  RF.startListening();

  // Serial.println("ESP32 B (Slave) sẵn sàng...");

  Wire.setPins(SDA,SCL);
  Wire.begin();
  pinMode(EncoderA1, INPUT);
  pinMode(EncoderB1, INPUT);
  pinMode(EncoderA2, INPUT);
  pinMode(EncoderB2, INPUT);
  pinMode(LED, OUTPUT);
  pinMode(Buzzer, OUTPUT);
  attachInterrupt(digitalPinToInterrupt(EncoderA1), readEncoderA1, CHANGE);
  attachInterrupt(digitalPinToInterrupt(EncoderB1), readEncoderB1, CHANGE);
  attachInterrupt(digitalPinToInterrupt(EncoderA2), readEncoderA2, CHANGE);
  attachInterrupt(digitalPinToInterrupt(EncoderB2), readEncoderB2, CHANGE);

  //Set-up MPU--------------------------------------------
  mpu6050.begin();
  mpu6050.calcGyroOffsets(true);
  //Set-up MPU--------------------------------------------

  lineTime.timer = 0;
  trajTime.timer = 0;
  upTrajTimer.timer = 0.1;

  // updateData();

  MasterStart.Stop = false;
  MasterStart.StartCircle = false;
  MasterStart.StartEight = false;
  MasterStart.StartP2P = false;
  MasterStart.StartPaint = false;
  trajdata.DownTrajData = false;
  RightPID.DownPIDData = false;
  LeftPID.DownPIDData = false;
  MasterStart.EndPaint = false;
  MasterStart.EnORCam = false;
  MasterStart.StartCam = false;
  //Ready
  digitalWrite(Buzzer,1);
  delay(800);
  digitalWrite(Buzzer,0);
}

void loop() {
  // Serial.printf("k: %d\n",k);
  lisRF();

  updateTraj();

  if(RightPID.DownPIDData == true){
    updateData();
    // lisRF();
    RightPID.DownPIDData == false;
  }
  if((MasterStart.EnORCam == false) || (MasterStart.EnORCam == true && MasterStart.StartCam == true)){
    velTime.now = millis()/1000.0;
    if(velTime.now - velTime.previous >= sampleTime && running == true){
      velTime.delta = velTime.now - velTime.previous;
      velTime.previous = velTime.now;
      // lisRF();

      if(MasterStart.StartCircle == true){
        // Serial.println("Run Circle");
        RunCircle();
      }else if(MasterStart.StartEight == true){
        // Serial.println("Run Eight");
        RunEight();
      }else if(MasterStart.StartP2P == true){
        // Serial.println("Run Point to Point");
        RunLine();
      }else if(MasterStart.StartPaint == true){
        RunPaint();
      }else if(MasterStart.Stop == true){
        motor1(0,0,0);
        motor2(0,0,0);
        // k = 0;
        // i = 0;
        trajTime.timer = 0;
        pointsNum = 0;
        paintNums = 0;
        return;
      }

      MotorLeft.v = VelMotor.velCal(enCount1, res, ig, R, 0.02);
      enCount1 = 0;
      MotorRight.v = VelMotor.velCal(enCount2, res, ig, R, 0.02);
      enCount2 = 0;
      // Serial.printf("%.3f,%.3f\n",MotorLeft.v,MotorRight.v);
      MotorRight.vPID = RightMotor.PIDCal(vRightTraj, MotorRight.v, 0.02, RightMotor.Kp, RightMotor.Ki, RightMotor.Kd, RightMotor.N);
      MotorLeft.vPID = LeftMotor.PIDCal(vLeftTraj, MotorLeft.v, 0.02, LeftMotor.Kp, LeftMotor.Ki, LeftMotor.Kd, LeftMotor.N);
      
      if(MotorRight.vPID > 10){
        motor1(1,0,abs(MotorRight.vPID));
      }else if(MotorRight.vPID < -10){
        motor1(0,1,abs(MotorRight.vPID));
      }else{
        motor1(0,0,0);
      }

      if(MotorLeft.vPID > 10){
        motor2(0,1,abs(MotorLeft.vPID));
      }else if(MotorLeft.vPID < -10){
        motor2(1,0,abs(MotorLeft.vPID));
      }else{
        motor2(0,0,0);
      }

      readMPU();
      if(MasterStart.EnORCam == false){
        FWKematic(MotorRight.v,MotorLeft.v,0.02);
      }else if(MasterStart.EnORCam == true){
        nowX = Cam.xCam;
        nowY = Cam.yCam;
      }
      SlaveData.vRight = MotorRight.v;
      SlaveData.vLeft = MotorLeft.v;
      SlaveData.x = nowX;
      SlaveData.y = nowY;
      SlaveData.vRightTraj = vRightTraj;
      SlaveData.vLeftTraj = vLeftTraj;
      // Serial.printf("xC: %.2f, yC: %.2f, pC: %.2f\n",nowX, nowY, nowPhi);
      if(MasterStart.Stop == false){
        RF.stopListening();
        sendRF(6, &SlaveData, sizeof(SlaveData));
      }
      // esp_err_t result = esp_now_send(MAC_PEER, (uint8_t *)&SlaveData, sizeof(SlaveData));
    }
  }
}
