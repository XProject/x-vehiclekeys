function main(){
    return {
        lock(){
            HttpsPost("Lock", {plate: this.plate})
        },
        unlock(){
            HttpsPost("Unlock", {plate: this.plate})
        },
        engine(){
            HttpsPost("Engine", {plate: this.plate})
        },
        trunk(){
            HttpsPost("Trunk", {plate: this.plate})
        },
        alarm(){
            HttpsPost("Alarm", {plate: this.plate})
        },
        listen(){
            window.addEventListener("message", (event) => {
                if (event.data.type == "OpenUI") {
                    document.getElementById("keyfob").style.display = "block";
                    this.plate = event.data.plate
                } else if (event.data.type == "CloseUI") {
                    document.getElementById("keyfob").style.display = "none";
                    this.plate = ""
                }
            })
            document.onkeyup = function(event){
                if (event.key == "Escape"){
                    document.getElementById("keyfob").style.display = "none";
                    HttpsPost("Close", {})
                    this.plate = ""
                }
            };
        }
    }
}

async function HttpsPost(callback = "", data = {}) {
    const response = await fetch(`https://${GetParentResourceName()}/${callback}`, {
        method: "POST",
        body: JSON.stringify(data)
    }).then(resp => resp.json());
}