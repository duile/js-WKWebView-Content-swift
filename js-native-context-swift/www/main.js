
//button点击事件
function buttonClick(){
    window.webkit.messageHandlers.OOXX.postMessage({className:'Accelerometer',functionName:'transformData'});
};

function accelerometerOnSuccess(acceleration){
    $("#kuan").width("acceleration.x")

};

function accelerometerOnError(e){
	
};


