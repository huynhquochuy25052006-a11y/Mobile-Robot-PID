//Master K:
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>
#include <Preferences.h>

#define CE_PIN 4
#define CSN_PIN 5

Preferences save;

RF24 RF(CE_PIN, CSN_PIN);

String MatlabData;
// float drawPoints[50][2];
double paintPoints[500][2];
int xP = 0, yP = 1;
long k = 0, h = 0;
double lastX, lastY;
double lastXC, lastYC , lastPC;
//Các đối tượng thời gian-------------------------
struct thoigian{
  float now = 0;
  float previous1 = 0;
  float previous2 = 0;
  float wait1 = 0;
  float wait2 = 0;
};
thoigian clkTime;
//Các đối tượng thời gian-------------------------

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
// Địa chỉ 2 ống truyền nhận
const byte addressTx[6] = "NODE1"; // gửi đến B
const byte addressRx[6] = "NODE2"; // nhận phản hồi từ B

void setup() {
  Serial.begin(115200);
  
  clkTime.wait1 = 0.05;
  clkTime.wait2 = 0.05;
  MasterStart.Stop = true;
  RF.begin();
  RF.setPALevel(RF24_PA_LOW);
  
  // Thiết lập ống ghi/đọc
  RF.openWritingPipe(addressTx);
  RF.openReadingPipe(1, addressRx);
  
  Serial.println("ESP32 A (Master) sẵn sàng...");

  save.begin("data",true);
  trajdata.r = save.getFloat("r",0);
  trajdata.a = save.getFloat("a",0);
  trajdata.b = save.getFloat("b",0);
  trajdata.vel = save.getFloat("v",0);
  LeftPID.KpL = save.getFloat("KpL",0);
  LeftPID.KiL = save.getFloat("KiL",0);
  LeftPID.KdL = save.getFloat("KdL",0);
  LeftPID.NL = save.getFloat("NL",0);
  RightPID.KpR = save.getFloat("KpR",0);
  RightPID.KiR = save.getFloat("KiR",0);
  RightPID.KdR = save.getFloat("KdR",0);
  RightPID.NR = save.getFloat("NR",0);
  save.end();
}

void trajectory(){
  if(MatlabData == "STARTCIRCLE"){
    MasterStart.StartCircle = true;
    MasterStart.StartEight = false;
    MasterStart.StartP2P= false;
    MasterStart.StartPaint = false;
    MasterStart.Stop = false;
    MasterStart.EndPaint = false;

    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if(MatlabData == "STARTEIGHT"){
    MasterStart.StartCircle = false;
    MasterStart.StartEight = true;
    MasterStart.StartP2P= false;
    MasterStart.StartPaint = false;
    MasterStart.Stop = false;
    MasterStart.EndPaint = false;

    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if(MatlabData == "STARTPTOP"){
    MasterStart.StartCircle = false;
    MasterStart.StartEight = false;
    MasterStart.StartP2P = true;
    MasterStart.StartPaint = false;
    MasterStart.Stop = false;
    MasterStart.EndPaint = false;

    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if(MatlabData == "STARTPAINT"){
    MasterStart.StartCircle = false;
    MasterStart.StartEight = false;
    MasterStart.StartP2P = false;
    MasterStart.StartPaint = true;
    MasterStart.Stop = false;
    MasterStart.EndPaint = false;

    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if (MatlabData == "PAINT") {
    MasterStart.StartCircle = false;
    MasterStart.StartEight = false;
    MasterStart.StartP2P = false;
    MasterStart.StartPaint = false;
    MasterStart.Stop = false;
    MasterStart.EndPaint = true;

    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if (MatlabData == "ENDPAINT") {
    MasterStart.StartCircle = false;
    MasterStart.StartEight = false;
    MasterStart.StartP2P = false;
    MasterStart.StartPaint = false;
    MasterStart.Stop = false;
    MasterStart.EndPaint = false;

    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if(MatlabData == "STOP"){
    MasterStart.StartCircle = false;
    MasterStart.StartEight = false;
    MasterStart.StartP2P= false;
    MasterStart.StartPaint = false;
    MasterStart.Stop = true;
    MasterStart.EndPaint = false;

    k = 0;
    h = 0;
    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if(MatlabData == "ENCODER"){
    MasterStart.EnORCam = false;
    MasterStart.StartCam = false;
    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if(MatlabData == "CAMERA"){
    MasterStart.EnORCam = true;    
    MasterStart.StartCam = false;
    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }else if(MatlabData == "STARTCAM"){
    MasterStart.StartCam = true;
    RF.stopListening();
    sendRF(1, &MasterStart, sizeof(MasterStart));
  }
}

void readData(){
  if(MatlabData == "UPLOAD"){
    RightPID.DownPIDData = true;

    RF.stopListening();
    sendRF(4, &RightPID, sizeof(RightPID));
  }else if(MatlabData == "DONEUP"){
    save.begin("data",false);
    save.putFloat("r",trajdata.r);
    save.putFloat("a",trajdata.a);
    save.putFloat("b",trajdata.b);
    save.putFloat("v",trajdata.vel);
    save.putFloat("KpL",LeftPID.KpL);
    save.putFloat("KiL",LeftPID.KiL);
    save.putFloat("KdL",LeftPID.KdL);
    save.putFloat("NL",LeftPID.NL);
    save.putFloat("KpR",RightPID.KpR);
    save.putFloat("KiR",RightPID.KiR);
    save.putFloat("KdR",RightPID.KdR);
    save.putFloat("NR",RightPID.NR);
    save.end();
    RightPID.DownPIDData = false;

    RF.stopListening();
    sendRF(4, &RightPID, sizeof(RightPID));
  }else{
    // Tách tọa độ X và Y
    int rIndex = MatlabData.indexOf("r:");
    int aIndex = MatlabData.indexOf(",a:");
    int bIndex = MatlabData.indexOf(",b:");
    int vIndex = MatlabData.indexOf(",v:");
    int pLIndex = MatlabData.indexOf(",pL:");
    int iLIndex = MatlabData.indexOf(",iL:");
    int dLIndex = MatlabData.indexOf(",dL:");
    int nLIndex = MatlabData.indexOf(",nL:");
    int pRIndex = MatlabData.indexOf(",pR:");
    int iRIndex = MatlabData.indexOf(",iR:");
    int dRIndex = MatlabData.indexOf(",dR:");
    int nRIndex = MatlabData.indexOf(",nR:");
    if (rIndex != -1 && aIndex != -1 && bIndex != -1 && vIndex != -1) {
      trajdata.r = MatlabData.substring(rIndex + 2, aIndex).toFloat();
      trajdata.a = MatlabData.substring(aIndex + 3, bIndex).toFloat();
      trajdata.b = MatlabData.substring(bIndex + 3, vIndex).toFloat();
      trajdata.vel = MatlabData.substring(vIndex + 3,pLIndex).toFloat();
      LeftPID.KpL = MatlabData.substring(pLIndex + 4,iLIndex).toFloat();
      LeftPID.KiL = MatlabData.substring(iLIndex + 4,dLIndex).toFloat();
      LeftPID.KdL = MatlabData.substring(dLIndex + 4,nLIndex).toFloat();
      LeftPID.NL = MatlabData.substring(nLIndex + 4,pRIndex).toFloat();
      RightPID.KpR = MatlabData.substring(pRIndex + 4,iRIndex).toFloat();
      RightPID.KiR = MatlabData.substring(iRIndex + 4,dRIndex).toFloat();
      RightPID.KdR = MatlabData.substring(dRIndex + 4,nRIndex).toFloat();
      RightPID.NR = MatlabData.substring(nRIndex + 4).toFloat();
      RF.stopListening();
      sendRF(2, &trajdata, sizeof(trajdata));
      delay(5);
      sendRF(3, &LeftPID, sizeof(LeftPID));
      delay(5);
      sendRF(4, &RightPID, sizeof(RightPID));
    }
  }
}

void readPoints(){
  if (MatlabData == "END") {
    trajdata.DownTrajData = true;

    RF.stopListening();
    sendRF(2, &trajdata, sizeof(trajdata));
  }else if (MatlabData == "UPTRAJ") {
    trajdata.DownTrajData = false;
    // MasterStart.Stop = true;
    RF.stopListening();
    sendRF(2, &trajdata, sizeof(trajdata));
  }else{
    // Tách tọa độ X và Y
    int xIndex = MatlabData.indexOf("X:");
    int yIndex = MatlabData.indexOf(",Y:");
    
    if(xIndex != -1 && yIndex != -1) {
      float x = MatlabData.substring(xIndex + 2, yIndex).toFloat();
      float y = MatlabData.substring(yIndex + 3).toFloat();

      drawTrajData.xPoint = x;
      drawTrajData.yPoint = y;

      RF.stopListening();
      sendRF(5, &drawTrajData, sizeof(drawTrajData));
    }
  }
}

void reloadData(){
  if(MatlabData == "OPEN"){
    while(MatlabData != "RELOADED"){
      Serial.printf("%.3f",trajdata.r);
      Serial.print(",");
      Serial.printf("%.3f",trajdata.a);
      Serial.print(",");
      Serial.printf("%.3f",trajdata.b);
      Serial.print(",");
      Serial.printf("%.3f",trajdata.vel);
      Serial.print(",");
      Serial.printf("%.3f",LeftPID.KpL);
      Serial.print(",");
      Serial.printf("%.3f",LeftPID.KiL);
      Serial.print(",");
      Serial.printf("%.3f",LeftPID.KdL);
      Serial.print(",");
      Serial.printf("%.3f",LeftPID.NL);
      Serial.print(",");
      Serial.printf("%.3f",RightPID.KpR);
      Serial.print(",");
      Serial.printf("%.3f",RightPID.KiR);
      Serial.print(",");
      Serial.printf("%.3f",RightPID.KdR);
      Serial.print(",");
      Serial.printf("%.3f\n",RightPID.NR);
      MatlabData = Serial.readStringUntil('\n');
    }
  }
}

void paintTraj(){
  int xIndex = MatlabData.indexOf("Xd:");
  int yIndex = MatlabData.indexOf(",Yd:");
  
  if (xIndex != -1 && yIndex != -1) {
    float x = MatlabData.substring(xIndex + 3, yIndex).toFloat();
    float y = MatlabData.substring(yIndex + 4).toFloat();
    // if(x != paintPoints[k-1][xP] || y != paintPoints[k-1][yP]){
    if(x != lastX || y != lastY){
      drawTrajData.xPaint = x;
      drawTrajData.yPaint = y;
      lastX = x;
      lastY = y;
    }
  }
  RF.stopListening();
  sendRF(5, &drawTrajData, sizeof(drawTrajData));
}

void readCam(){
  int xIndex = MatlabData.indexOf("xC:");
  int yIndex = MatlabData.indexOf(",yC:");
  int phiIndex = MatlabData.indexOf(",pC:");
  if (xIndex != -1 && yIndex != -1) {
    float x = MatlabData.substring(xIndex + 3, yIndex).toFloat();
    float y = MatlabData.substring(yIndex + 4, phiIndex).toFloat();
    float phi = MatlabData.substring(phiIndex + 4).toFloat();
    if(x != lastXC || y != lastYC || phi != lastPC){
      Cam.xCam = x;
      Cam.yCam = y;
      Cam.pCam = phi;
      lastXC = x;
      lastYC = y;
      lastPC = phi;
    }
  }
  RF.stopListening();
  sendRF(7, &Cam, sizeof(Cam));
}

// void sendPaint(){
//   drawTrajData.xPaint = paintPoints[h][xP];
//   drawTrajData.yPaint = paintPoints[h][yP];
//   if(h>=500){
//     h = 0;
//     // return;
//   }else{
//     h++;
//   }
//   RF.stopListening();
//   sendRF(5, &drawTrajData, sizeof(drawTrajData));
// }

void loop() {
  if(Serial.available()){
    MatlabData = Serial.readStringUntil('\n');    
    readCam();
    trajectory();
    readData();
    readPoints();
    reloadData();
    // paintTraj();
    clkTime.now = millis()/1000.0;
    if(MasterStart.EndPaint == true && clkTime.now - clkTime.previous2 >= 0.005){
      clkTime.previous2 = clkTime.now;
      // sendPaint();
      paintTraj();
    }
  }
  // }
  if(MasterStart.Stop == false){
    RF.startListening();
    if(RF.available()){
      RF.read(&pack, sizeof(pack));
      if(pack.id == 6){
        memcpy(&SlaveData, pack.data, sizeof(SlaveData));
        // Serial.printf("%.3f,%.3f,%.3f,%.3f,%.3f\n",SlaveData.vRight,SlaveData.vLeft,SlaveData.x,SlaveData.y,SlaveData.phi);
        Serial.printf("%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n",SlaveData.x,SlaveData.y,SlaveData.vRight,SlaveData.vLeft,SlaveData.vRightTraj,SlaveData.vLeftTraj);
      }
    }
  }
}
