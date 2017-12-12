module.exports = function(robot) {
    robot.router.get('/healthz', (req, res) => {
        res.json({ok: 200});
    });
};
