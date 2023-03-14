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
                    this.show = event.data.show
                    this.plate = event.data.plate
                } else if (event.data.type == "CloseUI") {
                    document.getElementById("keyfob").style.display = "none";
                    this.show = false
                    this.plate = ""
                }
            })
            document.onkeyup = function(event){
                if (event.key == "Escape"){
                    document.getElementById("keyfob").style.display = "none";
                    HttpsPost("Close", {})
                    this.show = false
                    this.plate = ""
                }
            };
        }
    }
}

async function HttpsPost(callback = "", data = {}) {
    const reponse = await fetch(`https://${GetParentResourceName()}/${callback}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json());
}