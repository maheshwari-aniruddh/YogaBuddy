const canvas = document.getElementById('canvas');








const ctx = canvas.getContext('2d');



canvas.width = 800;
canvas.height = 600;
let frame = 0;
let personX = 100;
let personY = 400;
let direction = 1;
const baseWalkSpeed = 2;



const slowSpeed = 1;






const fastSpeed = 3;





const hillStartX = 0;



const hillEndX = 800;






const hillPeakX = 300;








const hillPeakY = 200;





const groundY = 500;




const personHeight = 60;



const personWidth = 30;








const parabolaA = 0.003333;




const parabolaH = hillPeakX;








const parabolaK = hillPeakY;








function getHillY(x) {





    return parabolaA * Math.pow(x - parabolaH, 2) + parabolaK;
}





function getSlopeAngle(x) {



    const slope = 2 * parabolaA * (x - parabolaH);
    return Math.atan(slope);
}





function drawHill() {





    ctx.beginPath();
    ctx.moveTo(hillStartX, getHillY(hillStartX));
    for (let x = hillStartX; x <= hillEndX; x += 2) {
        ctx.lineTo(x, getHillY(x));
    }







    ctx.lineTo(hillEndX, canvas.height);
    ctx.lineTo(hillStartX, canvas.height);
    ctx.closePath();
    ctx.fillStyle = '#66BB6A';
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(hillStartX, getHillY(hillStartX));
    for (let x = hillStartX; x <= hillEndX; x += 2) {
        ctx.lineTo(x, getHillY(x));
    }



    ctx.lineTo(hillEndX, 0);
    ctx.lineTo(hillStartX, 0);
    ctx.closePath();
    ctx.fillStyle = '#64B5F6';
    ctx.fill();
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(hillStartX, getHillY(hillStartX));
    for (let x = hillStartX; x <= hillEndX; x += 2) {
        ctx.lineTo(x, getHillY(x));
    }




    ctx.stroke();
}








function drawPerson(x, y, frame) {



    ctx.save();
    ctx.translate(x, y);
    const slopeAngle = getSlopeAngle(x);
    ctx.rotate(slopeAngle);
    const facingRight = direction === 1;
    if (!facingRight) {
        ctx.scale(-1, 1);
    }




    const legOffset = Math.sin(frame * 0.3) * 8;
    const armOffset = Math.sin(frame * 0.3 + Math.PI) * 6;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.arc(0, -personHeight + 10, 8, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(0, -personHeight + 18);
    ctx.lineTo(0, -personHeight + 40);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(0, -personHeight + 25);
    ctx.lineTo(-8 - armOffset, -personHeight + 35);
    ctx.moveTo(0, -personHeight + 25);
    ctx.lineTo(8 + armOffset, -personHeight + 35);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(0, -personHeight + 40);
    ctx.lineTo(-6 - legOffset, -personHeight + 55);
    ctx.moveTo(0, -personHeight + 40);
    ctx.lineTo(6 + legOffset, -personHeight + 55);
    ctx.stroke();
    ctx.fillStyle = '#000';
    ctx.fillRect(-8 - legOffset, -personHeight + 55, 4, 3);
    ctx.fillRect(4 + legOffset, -personHeight + 55, 4, 3);
    ctx.restore();
}



function animate() {





    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drawHill();
    let currentSpeed;
    if (personX < hillPeakX) {
        currentSpeed = slowSpeed;
    } else {
        currentSpeed = fastSpeed;
    }





    personX += currentSpeed * direction;
    if (personX >= hillEndX) {
        personX = hillStartX;
    } else if (personX <= hillStartX) {
        personX = hillEndX;
    }





    personY = getHillY(personX) + 5;
    drawPerson(personX, personY, frame);
    ctx.fillStyle = '#000';
    ctx.textAlign = 'center';
    let progress;
    if (personX < hillPeakX) {
        progress = (personX - hillStartX) / (hillPeakX - hillStartX);
    } else {
        progress = (hillEndX - personX) / (hillEndX - hillPeakX);
    }



    progress = Math.max(0, Math.min(1, progress));
    const minFontSize = 16;
    const maxFontSize = 80;
    const fontSize = minFontSize + (maxFontSize - minFontSize) * progress;
    ctx.font = `bold ${fontSize}px Arial`;
    if (personX < hillPeakX) {
        ctx.fillText('inhale', canvas.width / 2, 80);
    } else {
        ctx.fillText('exhale', canvas.width / 2, 80);
    }






    ctx.save();
    ctx.fillStyle = '#000';
    ctx.font = 'bold 28px Arial';
    ctx.textAlign = 'left';
    ctx.fillText('Drink water, and find a quiet spot to breathe', 10, canvas.height - 30);
    ctx.restore();
    frame++;
    requestAnimationFrame(animate);
}



animate();