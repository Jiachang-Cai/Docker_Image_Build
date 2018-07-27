package main

import (
	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/static"
	"os"
)

func main()  {
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	router.Use(static.Serve("/", static.LocalFile("/dist", false)))
	router.NoRoute(func(c *gin.Context){
		c.File("/dist/index.html")
	})
	router.Run(":"+os.Getenv("PORT"))
}



