
const mongoose = require("mongoose");


const Database = new mongoose.Schema({

    clientcode: {
        type: Number,
        required: true
    },
    inputrequest: {
        reference_module: {
            type: String
        },
        reference_module_unique_row_id: {
            type: String
        }
    },
    isprocessed: {
        type: Boolean,
        default: false
    },
    createdby: {
        type: String,
        required: true
    },
    createddate: {
        type: Date,
        default: Date.now
    },
    modifyby: {
        type: String
    },
    modifieddate: {
        type: Date,
        default: null
    }
});

module.exports = mongoose.model('database', Database);



===========================event==================

// const date = require('joi/lib/types/date');
const schema = require('./EventSchema');

var events = {

    // insertevent to insert the data
    InsertEvent: async (req) => {
        const data = new schema({
            clientcode: req.body.clientcode,
            inputrequest: req.body.inputrequest,
            isprocessed: req.body.isprocessed,
            reference_module: req.body.reference_module,
            reference_module_unique_row_id: req.body.reference_module_unique_row_id,
            createdby: req.body.createdby,
            createddate: req.body.createddate,
            modifyby: req.body.modifyby,
            modifieddate: req.body.modifieddate
        });
        data.save();
        return data;
    },


    // updateevent to update ModifiedDate and IsProcessed 
    UpdateEvent: async (req) => {
        const upd = await schema.findByIdAndUpdate(req.body.id, [
            {
                $set: {
                    isprocessed: {
                        $cond: [{
                            $eq: ["$isprocessed", false]
                        },
                            true
                            , false
                        ]
                    },
                    modifieddate: Date.now()
                }
            }
        ]);
        await upd.save();
        return upd;
    }

}

module.exports = events;


=====================API========================
const config = require("../Config");
const Authentication = require('./Auth');
const events = require('../DataAccess/Mongo/Events');
const schema = require('../DataAccess/Mongo/EventSchema');
const axios = require("axios");

const url = config.EB_MongoCon_URL;

const mongoose = require("mongoose");
mongoose.connect(url);

const conn = mongoose.connection;
conn.on('open', () => {
    console.log("connected to db")
})



module.exports = function (app) {


    app.post("/processevent", function (req, res) {
        try {
            // console.log(req.body);
            var refModule = req.body.inputrequest.reference_module;
            var ClientCode = req.body.inputrequest.reference_module_unique_row_id;
            var jsonData = {
                "ClientCode": "-QW67",
                "InputRequest": {
                    "reference_module": refModule,
                    "reference_module_unique_row_id": ClientCode
                },
                "IsProcessed": "False",
                "CreatedBy": "1234567852",
                "CreatedDate": "kdmodi",
                "ModifiedBy": "kdmodi",
                "ModifiedDate": "ModifiedDate"
            }
            Authentication(req);
            if (Authentication(req) == 'true') {
                events.InsertEvent(req);
                axios({
                    url: "http://192.168.2.25:3123/eventprocess",
                    method: 'POST',
                    headers: {
                        "Content-Type": "application/json"
                    },
                    data: jsonData
                }).then((result) => {
                    console.log(result.data);
                })
                res.send('Data Inserted Successfully');
            }
            else {
                res.send("Authentication invalid");
            }
        }
        catch (err) {
            res.send({ "Error": "Error" });
        }
    });

    // put method fro update 
    app.put('/processevent', (req, res) => {
        try {
            events.UpdateEvent(req);
            res.send("Data updated Successfully");
        } catch (err) {
            res.send('Error' + err)
        }
    })


    // for checking data
    app.get('/getevent', async (req, res) => {
        try {
            const data = await schema.find();
            res.json(data);
        } catch (error) {
            console.log(`Error : ${error}`);
        }
    })


};

==================auth=========================
const config = require('../Config.js');

const Authentication = (req) => {

    // get the authorization key from headers
    var AuthKey = req.headers.authorization

    // check authentication key 
    if (config.Authorization === AuthKey) {
        return 'true'
    }
    else {
        return 'false'
    }
}
module.exports = Authentication;
