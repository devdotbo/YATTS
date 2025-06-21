my dirty promts:

1.
 plan an architect a simple, yet fully working TTS (text to speak) ios app that uses the swiftData for the store, that has a   │
│   list of items to read. a iteam is in our case the audio file that can be played if its selected. a iteam can be deleted with  │
│   the typical swipe gesture and a confirmation. a item an be added, in this case, the user user gets a text field (for large    │
│   texts!!!). usually, the user copy paste text there. and then it confirms. after that, the data is send ou the openai api,     │
│   and we get back the audio file (for example mp3). this audio file must be stored on the device. so it always can be           │
│   accasible. also, we want also make sure that the past position of the audio file is stored and if the user pauses or clsoed  │
│   the app, the position onctinues. also, the user can skip 15 sec forward. the user also has a setting ienrface where the user  │
│   has to put is ipenai key. ultrathink. plan. architect. decide if we ether use a this package                                  │
│   https://github.com/MacPaw/OpenAI/blob/main/README.md or the pure api https://platform.openai.com/docs/guides/text-to-speech  

good. now create the needed files like claude.md and another file plan.md with tasks and everyting what is needed. for you   │
│   in order to execute that.   

execute now the plan in full. no todos left. it should fully working. so i can run it on my device. commit every step. start  │
│   with the first commit now. but first check git status and if we to update git ignore.         

try to build it. it will fail. 

I get 400 http error if i try to paste a large text (60 chars). what there limit there? this are the logs [Pasted text #1 +5  │
│   lines]

ultrathink, plan, architect and then execute how we can chunk that intro multible requests, so we are not limited the the     │
│   4096. but still, the chunks should be vislible for the user (amount of chunks, and in the download proces chunk 1,2 ,3        │
│   etc...). also the player needs to handle it. and as well as the storage system. create also completete tests (use this api    │
│   key for the actual testing: XXXX). the api key should be in a enviroment file. that env.  │
│   file should not be commited (gitignore) 


