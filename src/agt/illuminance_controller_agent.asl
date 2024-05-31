//illuminance controller agent

/*
* The URL of the W3C Web of Things Thing Description (WoT TD) of a lab environment
* Simulated lab WoT TD: "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/interactions-lab.ttl"
* Real lab WoT TD: Get in touch with us by email to acquire access to it!
*/

/* Initial beliefs and rules */

// the agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a lab environment to be learnt
learning_lab_environment("https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/interactions-lab.ttl").
lab_environment("https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/interactions-lab-real.ttl").

// the agent believes that the task that takes place in the 1st workstation requires an indoor illuminance
// level of Rank 2, and the task that takes place in the 2nd workstation requires an indoor illumincance 
// level of Rank 3. Modify the belief so that the agent can learn to handle different goals.
task_requirements([2,3]).

real(false).

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that there is a WoT TD of a lab environment located at Url, and that 
 * the tasks taking place in the workstations require indoor illuminance levels of Rank Z1Level and Z2Level
 * respectively
 * Body: (currently) creates a QLearnerArtifact and a ThingArtifact for learning and acting on the lab environment.
*/
@start
+!start : learning_lab_environment(Url) 
  & task_requirements([Z1Level, Z2Level]) <-

  .print("Hello world");
  .print("I want to achieve Z1Level=", Z1Level, " and Z2Level=",Z2Level);

  // creates a QLearner artifact for learning the lab Thing described by the W3C WoT TD located at URL
  makeArtifact("qlearner", "tools.QLearner", [Url], QLArtId);
  calculateQ([Z1Level, Z2Level],200,0.3,0.9,0.2,100)[artifact_id(QLArtId)];

  !makeTdArtifact(LabArtId);
  !achieveTask(Z1Level, Z2Level, LabArtId);



  // example use of the getActionFromState operation of the QLearner artifact
  // relevant for Task 2.3
  // getActionFromState([Z1Level,Z2Level], [0, 0, false, false, false, false, 3], ActionTag, PayloadTags, Payload)[artifact_id(QLArtId)];

  // example use of the invokeAction operation of the ThingArtifact 
  //invokeAction(ActionTag, PayloadTags, Payload)
  .

// plan to make artifact if learning environment is chosen
+!makeTdArtifact(LabArtId) : real(true) & lab_environment(Url) <-
  .print("Using real environment!");
  makeArtifact("lab", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], LabArtId).
  
// plan to make artifact if real lab is chosen  
+!makeTdArtifact(LabArtId) : real(false) & learning_lab_environment(Url) <-
  .print("Using learning environment!");
  makeArtifact("lab", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], LabArtId).

// plan that will try to achieve the goal levels
+!achieveTask(Z1Level, Z2Level, LabArtId) : true <-
  // read current state and put it into a Map
  // in case the returned arrays are not always in the same order
  readProperty("https://example.org/was#Status", Key, Value)[artifact_id(LabArtId)];
  .map.create(M);  
  .length(Key, KLength);
  for ( .range(I,0,KLength - 1) ) {
    .nth(I,Key,K);
    .nth(I,Value,V);
    .map.put(M,K,V);
  };
  .map.get(M,"http://example.org/was#Z2Level",Z2LevelRead);
  .map.get(M,"http://example.org/was#Z1Blinds",Z1BlindsRead);
  .map.get(M,"http://example.org/was#Sunshine",SunshineRead);
  .map.get(M,"http://example.org/was#Z2Light",Z2LightRead);
  .map.get(M,"http://example.org/was#Z1Light",Z1LightRead);
  .map.get(M,"http://example.org/was#Z2Blinds",Z2BlindsRead); 
  .map.get(M,"http://example.org/was#Z1Level",Z1LevelRead); 
  
  // use the function from lab to discretice the read values
  discretizeLightLevel(Z1LevelRead, DisZ1);
  discretizeLightLevel(Z2LevelRead, DisZ2);
  discretizeSunshine(SunshineRead, Sunshine);

  // if the read values are the the ones we want we can simply tell that we did it.
  if (DisZ1 == Z1Level & DisZ2 == Z2Level) {
    .print("Achieved wanted levels!");
  // else we get the next best action and invoke it. Then we wait and execute this plan again.
  } else {
      getActionFromState([Z1Level,Z2Level], [DisZ1,DisZ2,Z1LightRead,Z2LightRead,Z1BlindsRead,Z2BlindsRead,Sunshine], ActionTag, PayloadTags, Payload)[artifact_id(QLArtId)];
      .print("Perform action: ", ActionTag, " PayloadTags: ", PayloadTags, " Payload: ", Payload);
      invokeAction(ActionTag, PayloadTags, Payload)[artifact_id(LabArtId)];
      .wait(5000);
      !achieveTask(Z1Level, Z2Level, LabArtId);
    }.
  
