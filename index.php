<?php
    $servername = "localhost:3306";
    $username = "root";
    $password = "root";
    $dbname = "prova";

    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    } 
    echo "Connected successfully\n";
    $data = json_decode(file_get_contents('php://input'), true);
    $path= $data["pathFile"];
    $images = $data["images"];
    //INSERISCO LE IMMAGINI NEL DATABASE
    foreach($images as $arr) {      
        $url=$path.$arr["fileName"];
        $nome=$arr["fileName"];
        $tags = $arr["tags"];
        echo $arr["fileName"]."\t".implode(", ",$arr["tags"])."\n";
        $image_db = $conn->query("SELECT id FROM fotografia WHERE url='$url'");
        $foto_id=0;
        //SE NON VI SONO IMMAGINI CON STESSO PATH NEL DB, LE INSERISCO
        if(empty($image_db) || $image_db->num_rows==0){
            if ($conn->query("INSERT INTO fotografia (url, nome) VALUES ('$url', '$nome')") === TRUE) {  
                echo "\nImmagine inserita, aggiungo i tag\n";
                $foto_id = $conn->insert_id;    //ultimo ID inserito in Fotografia
            } 
            //C'E' STATO UN ERRORE NELL'INSERIMENTO DELL'IMMAGINE
            else {       
                echo "\nError: ". $conn->error."\n";
            }
        }
        //ALTRIMENTI MI PRENDO L'ID E VERIFICO CHE I TAG SIANO GLI STESSI
        else{
            $foto_id=$image_db->fetch_assoc();
            $foto_id=$foto_id['id'];
        }
        //INSERISCO I TAG, TENENDO CONTO DI QUELLI GIA' PRESENTI NEL DB
        foreach($tags as $tag){    
            $result = $conn->query("SELECT id FROM tags WHERE nome='$tag'");
            $tag_id=0;
            //HO TROVATO UN TAG NEL DATABASE, PRENDO IL SUO ID
            if (!empty($result) && $result->num_rows > 0) {    
                $row = $result->fetch_assoc();
                $tag_id = $row["id"];
            } 
            //NON HO TROVATO UN TAG UGUALE NEL DATABASE, LO INSERISCO
            else {
                $tag=strtolower($tag);                       
                if ($conn->query("INSERT INTO tags (nome) VALUES ('$tag')") === TRUE) {
                    $tag_id=$conn->insert_id;
                }
                //C'E' STATO UN ERRORE NELL'INSERIMENTO DEL NUOVO TAG
                else {      
                    echo "\n\t\tError: ". $conn->error."\n";
                }
            }
            if($foto_id!=0 && $tag_id!=0){  //controllo che i valori di foto_id e tag_id siano stati settati correttamente
                //INSERISCO LE ASSOCIAZIONI CON I TAG NELLA TABELLA foto_tag SOLO SE NON SONO GIA' PRESENTI
                $foto_tag_presenti = $conn->query("SELECT * FROM foto_tag WHERE id_foto='$foto_id' AND id_tag='$tag_id'");
                if(empty($foto_tag_presenti) || $foto_tag_presenti->num_rows == 0){
                    if ($conn->query("INSERT INTO foto_tag (id_foto, id_tag) VALUES ('$foto_id', '$tag_id')") === TRUE) {
                        echo $tag." :Associazione creata\n";
                    }
                    //C'E' STATO UN ERRORE NELL'INSERIMENTO DEI TAG
                    else {      
                        echo "\n\tError: ". $conn->error."\n";
                    }
                }
            }
        }
    }
    $conn->close();
?>