/*
Common usage file here are stored some values that can be used throughout the app
*/

let fm = FileManager.default

guard let BaseDataURL = fm.urls(for: .documentDirectory, //base url for storing data such as reviews or goals
                                     in:.userDomainMask).first else
        {
            return
        }

let ReadBooksURL=BaseDataURL.appendingPathComponent("ReadBooks") //base directory for storing reviews

let GoalsURL=BaseDataURL.appendingPathComponent("Goals")//base directory for storing goals
