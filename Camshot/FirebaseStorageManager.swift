//
//  FirebaseStorageManager.swift
//  Camshot
//
//  Created by Timi Tejumola on 08/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import UIKit
import Firebase

class FirebaseStorageManager {

    public func uploadMetadata(localFile: URL, serverFileName: String, filter: String?, completionHandler: @escaping (_ isSuccess: Bool, _ documentID: String?) -> Void) {

        let db = Firestore.firestore()
        
        var ref: DocumentReference? = nil
        ref = db.collection("videos").addDocument(data: [
            "filter": filter,
            "filename": serverFileName
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                completionHandler(false, nil)
            } else {
                print("Document added with ID: \(ref!.documentID)")
                completionHandler(true, ref!.documentID)
            }
        }
    }
}
