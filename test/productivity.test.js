import test from "node:test";
import assert from "node:assert/strict";
import{parseGoal,matches,detect,weeklyReport}from"../lib/productivity.js";
test("parses tracked habits",()=>assert.deepEqual(parseGoal("Gym 0/7 days"),{text:"Gym",current:0,target:7}));
test("matches natural language",()=>{assert.equal(matches("I got groceries after work","Get groceries"),true);assert.equal(matches("Read a book","Call dentist"),false)});
test("detects task and goal",()=>{const result=detect("Went to the gym and got groceries",[{text:"Get groceries",done:false}],[{text:"Gym",current:0,target:7}]);assert.equal(result.tasks.length,1);assert.equal(result.goals.length,1)});
test("builds report",()=>{const state={goals:[{text:"Gym",current:2,target:7}],days:{"2026-06-08":{date:"2026-06-08",tasks:[{text:"Build homepage",done:true}],note:"Built it."}}};assert.match(weeklyReport(state,new Date("2026-06-10T12:00:00")),/Build homepage/)});
