

function maketext()
	
	dw# = GetDeviceWidth()
	if GetTextExists(1) // delete texts if they already exist
		for t = 1 to 4
			DeleteText(t)
		next t
	endif
	
	titlesize# = 45
	textsize# = 35

	//position the exit button
	SetSpritePosition(exit_button,GetScreenBoundsright()-GetSpriteWidth(exit_button)-5,GetScreenBoundsTop()+5)

	CreateText(1, "Bubbles with Types")
	SetTextPosition(1,GetScreenBoundsLeft()+5,GetScreenBoundsTop()+5)
	SetTextSize(1,titlesize#)
	DeleteTextBackground(tbg1)
	tbg1 = CreateTextBackground(1,1,8,5,100)
	SetTextBackgroundColor(tbg1,0,0,0,155)

	CreateText(2, "FPS: "+str(ScreenFPS(),0) ) // Display the frame rate
	SetTextAlignment(2,1)
	SetTextPosition(2,GetSpriteXByOffset(exit_button),GetScreenBoundsTop()+GetSpriteHeight(exit_button)+5)
	SetTextSize(2,textsize#*0.8)

	CreateText(3, "Pop the bubbles." ) // Display some simple instructions
	SetTextPosition(3,GetScreenBoundsLeft()+5,GetScreenBoundsTop()+60)
	SetTextSize(3,textsize#)
	DeleteTextBackground(tbg2)
	tbg2 = CreateTextBackground(3,1,8,5,100)
	SetTextBackgroundColor(tbg2,0,0,0,155)

	CreateText(4, "Score "+str(score)+"   Hi-Score "+str(highscore) )
	SetTextPosition(4,GetScreenBoundsLeft()+5,GetScreenBoundsTop()+105)
	SetTextSize(4,textsize#)
	DeleteTextBackground(tbg3)
	tbg3 = CreateTextBackground(4,1,8,5,100)
	SetTextBackgroundColor(tbg3,0,0,0,155)

	//re-size and position background image to fit
	setspritesize(1,GetScreenBoundsRight()-GetScreenBoundsLeft(), GetScreenBoundsBottom() - GetScreenBoundsTop())
	SetSpritePosition(1,GetScreenBoundsLeft(),GetScreenBoundsTop())

endfunction
