# This script is to explore whether PlanetScope can pick up differences in tree phenology or pollen cone density
# PlanetScope data was downloaded by Yiluan and emailed to DK on Nov. 16, 2023
# Phenology data comes from measurements by DK in Dec 2019 - Feb 2020 & Dec 2020 - Jan 2021 and associated models
# Pollen cone abundance comes from coarse visual assessments by DK in first field season
# additional comparisons to female trees are available for the Wade site (made by DK in Jan 2023)
# there are also photos of all trees measured during field seasons, so those could work too

#set up work environment
#rm(list=ls())
library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(sf)
library(lubridate)


### loading data

#load trees from wade jan 23
wade23 <- readr::read_csv("C:/Users/dsk273/Box/texas/pheno/Jan 2023 fieldwork/Wade_pheno_sex_obs_jan23_male_vs_female.csv")

# #load planetscope data from Yiluan
# ps <- readr::read_csv("C:/Users/dsk273/Box/texas/pheno/juniper_planet_indices_from_yiluan231129.csv") %>% 
#   mutate(lon = round(lon, 5),
#          lat = round(lat, 5)) #preventing some floating point errors later on



#load planetscope data from Yiluan 7/17/24
ps <- readr::read_csv("C:/Users/dsk273/Box/texas/pheno/juniper_planet_indices_from_yiluan240717.csv") %>% 
  mutate(date_p = mdy(date),
         c_group = group,
         lon = round(lon, 5),
         lat = round(lat, 5), #preventing some floating point errors later on
         hue = rgb2hsv(ps$red, ps$green, ps$blue, maxColorValue = 1)[1,],
         sat = rgb2hsv(ps$red, ps$green, ps$blue, maxColorValue = 1)[2,],
         val = rgb2hsv(ps$red, ps$green, ps$blue, maxColorValue = 1)[3,],
         rgb_tot = red + green + blue) %>% 
  mutate(rg_dif = (red - green)/(red + green),
         rg_dif2 = (red + green)/(red + green + blue)) 

#time series 
ps %>% 
  mutate(focal_index = rg_dif) %>% 
  #filter(rgb_tot > 0.3  & rgb_tot < 1) %>% 
  filter(c_group == "green") %>% 
  #filter(id < 10) %>% 
  filter(site == "Burnet") %>% 
  filter(date_p > ymd("2022/11/01")) %>% 
 # filter(c_group == "orange") %>% 
  filter(rgb_tot > 0.1  & rgb_tot < 1) %>% 
ggplot( aes(x = date_p, y = focal_index, color = c_group, group = id)) + #geom_point(alpha = 0.1) + 
  theme_bw() +
  geom_line(aes(y=zoo::rollmean(focal_index, 6, na.pad=TRUE)), alpha = 0.6) +
  scale_color_manual(values = c( "green", "orange")) + facet_wrap(~site) +
  geom_point(alpha = 0.91)





#normalizing by green trees
tree_date_band_means <- ps %>% 
  filter(c_group == "green") %>% 
  group_by(site, date ) %>% 
  summarize(r_mean_fem = median(red),
            g_mean_fem = median(green),
            b_mean_fem = median(blue),
            nir_mean_fem = median(nir))
  
#ps2 <- 
left_join(ps, tree_date_band_means) %>%  
  mutate(r_norm = red/r_mean_fem,
         g_norm = green/g_mean_fem,
         b_norm = blue/b_mean_fem,
         nir_norm = nir/nir_mean_fem,
         
         focal_index = (red - green)/(red + green) 
          # (red - green)/(red + green) - (r_mean_fem - g_mean_fem)/(r_mean_fem + g_mean_fem)
         #(r_norm - g_norm)/(r_norm + g_norm) #(red - green)/(red + green) 
         ) %>% 
  #filter(rgb_tot > 0.3  & rgb_tot < 1) %>% 
  #filter(c_group == "orange") %>% 
  #filter(id < 10) %>% 
  filter(red < 0.1 & green < 0.1 & nir < 0.3) %>% 
  filter(site == "Burnet") %>% 
  filter(id == 42 ) %>% 
 # filter(date_p > ymd("2020/9/01") & date_p < ymd("2021/3/01")) %>% 
  # filter(c_group == "orange") %>% 
  filter(rgb_tot > 0.1  & rgb_tot < 1) %>% 
  ggplot( aes(x = date_p, y = focal_index, color = c_group, group = id)) + #geom_point(alpha = 0.1) + 
  theme_bw() +
  geom_line(aes(y=zoo::rollmean(focal_index, 14, na.pad=TRUE)), alpha = 1) +
  scale_color_manual(values = c( "orange")) + 
  facet_wrap(~id) +
  scale_x_date(limits = c(ymd("2020/9/01"), ymd("2021/5/01")))+
  geom_point(alpha = 0.85)  + facet_wrap(~id) + ylab("spectral index") + xlab("date") 


example_tree <- ps %>%
  filter(site == "Burnet" & id == 42)



#trying to color the points by actual rgb values
hist(ps$red)
ps %>% 
  mutate(
         rgb_tot = red + green + blue,
         rg_dif = (red - green)/(red + green),
         rg_dif2 = (red + green)/(red + green + blue),
         focal_index = rgb_tot) %>% 
  #filter(id < 10) %>% 
  #filter(site == "Burnet") %>% 
 # filter(year > 2023) %>% 
  # filter(c_group == "orange") %>% 
  ggplot( aes(x = date_p, y = focal_index, color = rgb(red*2, green*2, blue*2), group = id)) + #geom_point(alpha = 0.1) + 
  theme_bw() +
  geom_line(aes(y=zoo::rollmean(focal_index, 28, na.pad=TRUE)), alpha = 0.6) +
  scale_color_identity() + facet_wrap(~site) +
  geom_point(alpha = 0.1)




rgb2hsv()
test <- rgb2hsv(ps$red, ps$green, ps$blue, maxColorValue = 1)[1,]
str(test)
test <- rgb2hsv(c(0.5 ,1 ,1 ,1), c(0.5 ,1, 1, 1), c(0.5 ,1, 1, 1), maxColorValue = 1)


?rgb2hsv
#summary 
ps %>% 
  mutate( c_month = month(date_p),
          pol_season = case_when(doy < 30 ~ "pollen season",
                                 doy > 29.5 & doy <330.5 ~ "not pollen season",
                                 doy > 330 ~"pollen season"),
          rgb_tot = red + green + blue,
          rg_dif = (red - green)/(red + green),
          rg = red - green,
         rg_dif2 = (2*red + green)/(red + green + blue),
         focal_index = rg_dif2) %>% 

  #filter(id < 10) %>% 
  filter(site == "Burnet") %>% 
  #filter(year > 2023) %>% 
  group_by(c_group, site, c_month) %>% 
  summarise(mean_focal_index = mean(focal_index)) %>% 
  ggplot( aes(x = c_month, y = mean_focal_index, color = c_group)) + #geom_point(alpha = 0.1) + 
  theme_bw() +
  geom_point() + 
  #geom_line(aes(y=zoo::rollmean(mean_focal_index, 28, na.pad=TRUE)), alpha = 0.6) +
  scale_color_manual(values = c( "green", "orange")) + facet_wrap(~site)




#time series 
ps %>% 
  mutate(rg_dif = (red - green)/(red + green),
         rg_dif2 = (red + green)/(red + green + blue),
         focal_index = (2*red + green)/(red + green + blue))  %>% 
  #filter(id < 10) %>% 
  filter(site == "Burnet") %>% 
  group_by(c_group,date_p) %>% 
  summarize(focal_index_mean = mean(focal_index)) %>% 
  filter(date_p > ymd("2021/11/01")) %>% 
  # filter(c_group == "orange") %>% 
  ggplot( aes(x = date_p, y = focal_index_mean, color = c_group)) + #geom_point(alpha = 0.1) + 
  theme_bw() +
  geom_line(aes(y=zoo::rollmean(focal_index_mean, 28, na.pad=TRUE)), alpha = 0.6) +
  scale_color_manual(values = c( "green", "orange")) 

# original script used to export  tree coordinates and date for Yiluan
# p1920 <- readr::read_csv("C:/Users/dsk273/Box/texas/pheno/manual_obs/pheno_clean_fs19_20_210910.csv")
# trees_2019_2020 <- p %>% dplyr::select(sample_date = dates, x, y)
# 
# p2021 <- readr::read_csv("C:/Users/dsk273/Box/texas/pheno/manual_obs/pheno_fs20_21_database_210402.csv")
# trees_2020_2021 <- p %>% dplyr::select(sample_date, x, y)
# 
# trees_dates_coords <- bind_rows(trees_2019_2020, trees_2020_2021) %>% distinct()
# write_csv(trees_dates_coords, here("texas", "pheno",  "tree_dates_coords_220930.csv"))



### male trees at wade #########################
wade_x_min <- min(wade23$x)
wade_x_max <- max(wade23$x)
wade_y_min <- min(wade23$y)
wade_y_max <- max(wade23$y)

## adding in 20-21 field season trees
p2021 <- readr::read_csv("C:/Users/dsk273/Box/texas/pheno/manual_obs/pheno_fs20_21_database_210402.csv")

p2021_wade <- p2021 %>% 
  filter(x > wade_x_min & x < wade_x_max) %>% 
  filter(y > wade_y_min & y < wade_y_max) %>% 
  mutate(x_join = round(x, 5),
         y_join = round(y, 5))

ps_wade <- ps %>% 
  filter(lon > wade_x_min & lon < wade_x_max) %>% 
  filter(lat > wade_y_min & lat < wade_y_max) %>% 
  mutate(x_join = round(lon, 5),
         y_join = round(lat, 5)) %>% 
  rename(ps_date = date) 


ps_p2021_wade_male <- 
  left_join(ps_wade, p2021_wade, multiple = "first") %>% 
  filter(!is.na(GlobalID)) %>% 
  mutate(xy = paste(x_join, y_join),
         ps_date = mdy(ps_date)) %>% 
  #filter(ps_date == ymd("2020-01-03")) %>% 
  distinct_at(vars(-id))  #removing the duplicated trees



### female trees at wade from Jan 23 #######################
wade_x_min <- min(wade23$x)
wade_x_max <- max(wade23$x)
wade_y_min <- min(wade23$y)
wade_y_max <- max(wade23$y)

ps_wade_female <- ps %>% 
  filter(lon > wade_x_min & lon < wade_x_max) %>% 
  filter(lat > wade_y_min & lat < wade_y_max) %>% 
  mutate(x_join = round(lon, 5),
         y_join = round(lat, 5))

wade23_join <- wade23 %>% 
  rename(id = GlobalID,
         date2 = date)
  # mutate(x_join = round(x, 5),
  #        y_join = round(y, 5))

ps_wade23_female <- left_join(ps_wade_female, wade23_join) %>% 
  mutate(xy = paste(x_join, y_join),
         ps_date = mdy(date)) %>% 
  filter(!is.na(cone_density))  %>%  
  #filter(ps_date == ymd("2020-01-03")) %>% 
  distinct_at(vars(-id))  #removing the duplicated trees

#coordinates at wade where YS extracted PS imagery (+'s vs the 2023 data)
ps_wade %>% 
  dplyr::select(x_join, y_join) %>% 
  distinct() %>% 
  ggplot(aes(x = x_join, y = y_join)) + geom_point(color = "black", size = 3, shape =3) + theme_bw() +
  geom_point(data = wade23_join, aes(x = x, y = y, color = sex))


### male vs female trees at Wade ########################################

#visualize Hannah's index over time using a moving average
ps_wade23_female <- ps_wade23_female %>% 
  mutate(hz_index = red + blue * 0.7)

ps_p2021_wade_male %>% 
  mutate(hz_index = red + blue * 0.7) %>% 
  #filter(id == "04527a0c-d540-416c-a406-53421add280f") %>% 
  ggplot(aes(x = ps_date, y = hz_index, group = xy )) + theme_bw() + 
  # geom_line(aes(y=zoo::rollmean(hz_index, 7, na.pad=TRUE)), alpha = 0.6, color = "orange") +
  # geom_line(data = ps_wade23_female, aes(y=zoo::rollmean(hz_index, 7, na.pad=TRUE)), alpha = 0.6, color = "green") +
  geom_point(data = ps_wade23_female, aes(x = ps_date, y = hz_index), color = "green") +
  geom_point(color = "orange", size = 2, alpha = 0.5) +
  scale_x_date(date_breaks = "1 month", 
               limits = as.Date(c('2019-12-01','2020-05-01')))




#visualize reflectivity over time using yellowness as a function of cone density
# #male trees
# ps_p2021_wade_male %>% 
# #filter(id == "04527a0c-d540-416c-a406-53421add280f") %>% 
# ggplot(aes(x = ps_date, y = yellow, group = id)) + #geom_point(alpha = 0.2) + geom_line(alpha = 0.2)  + facet_wrap(~id) +
#   geom_line(aes(y=zoo::rollmean(yellow, 14, na.pad=TRUE)), alpha = 0.2) + theme_bw()
# 
# #female trees
# ps_wade23_female %>%
#   #filter(id == "04527a0c-d540-416c-a406-53421add280f") %>% 
#   ggplot(aes(x = ps_date, y = yellow, group = id)) + #geom_point(alpha = 0.2) + geom_line(alpha = 0.2)  + facet_wrap(~id) +
#   geom_line(aes(y=zoo::rollmean(yellow, 14, na.pad=TRUE)), alpha = 0.2) + theme_bw()

#male and female at the same time
ps_p2021_wade_male %>% 
  #filter(id == "04527a0c-d540-416c-a406-53421add280f") %>% 
  ggplot(aes(x = ps_date, y = yellow, group = xy)) + theme_bw() + 
  #geom_point(color = "orange", size = 1.5) + 
  geom_line(data = ps_wade23_female, aes(y=zoo::rollmean(yellow, 14, na.pad=TRUE)), alpha = 0.6, color = "green") +
  geom_line(aes(y=zoo::rollmean(yellow, 14, na.pad=TRUE)), alpha = 0.6, color = "orange") + 
  
    #geom_point(data = ps_wade23_female, aes(x = ps_date, y = r2g), color = "green") +
  scale_x_date(#date_breaks = "12 month", 
               limits = as.Date(c('2016-12-01','2023-05-01')))






#create a map of trees on a particular day
ps_p2021_wade_male_join <- ps_p2021_wade_male %>% 
  dplyr::select(xy, ps_date, x = x_join, y = y_join, blue, green, red, nir, evi) %>% 
  mutate(sex = "male")

ps_p2021_wade_female_join <- ps_wade23_female %>% 
  dplyr::select(xy, ps_date, x, y, blue, green, red, nir, evi) %>% 
  mutate(sex = "female")

ps_p2021_wade <- bind_rows(ps_p2021_wade_male_join, ps_p2021_wade_female_join)  


ps_p2021_wade %>% 
  filter(ps_date == ymd("2022-05-29"))  %>% 
  mutate(hz_index = red + blue * 0.7) %>% 
  ggplot(aes(x = x, y = y, color = hz_index, shape = sex)) + geom_point(size = 2) + theme_bw() +
  scale_color_viridis_c()

unique(ps_p2021_wade$ps_date)


# a little map of ID numbers
ps_p2021_wade %>% 
  filter(ps_date == ymd("2022-05-29"))  %>% 
  mutate(hz_index = red + blue * 0.7) %>% 
  ggplot(aes(x = x, y = y, label = xy)) + geom_text(alpha = 0.1) + theme_bw() +
  scale_color_viridis_c()


#differences between hz index for all male and female trees at wade over a window
ps_p2021_wade %>% 
  filter(ps_date > ymd("2020-12-01") & ps_date <  ymd("2021-05-01")) %>% 
  mutate(hz_index = (red + blue * 0.7)) %>% 
  ggplot(aes(x = ps_date, y = hz_index, color = sex, group = xy)) + geom_point(alpha = 0.2) + theme_bw() + 
  geom_line() +
  scale_color_manual(values = c("green", "orange"))

  #scale_x_date(date_breaks = "1 month", limits = as.Date(c('2020-12-01','2021-04-01')))

#boxplots of hz index for all male and female trees over a defined time window  
  ps_p2021_wade %>% 
    #filter(ps_date > ymd("2020-12-01") & ps_date <  ymd("2021-02-01")) %>% 
    filter(ps_date > ymd("2021-1-01") & ps_date <  ymd("2021-02-01")) %>% 
 #   filter(ps_date > ymd("2021-5-01") & ps_date <  ymd("2021-6-01")) %>% 
    mutate(hz_index = red + blue * 0.7) %>% 
    ggplot(aes(x = sex, y = hz_index, fill = sex)) + geom_jitter(alpha = 0.2) + theme_bw() + 
    geom_boxplot() + facet_wrap(~ps_date) +
    scale_fill_manual(values = c("green", "orange"))

  
  
  # #visualize time series from a couple of similar trees, including high cone males and similar structure females
  # # a high cone tree
  # ps_p2021_wade %>% 
  #   # filter(y > 30.8260 & y < 30.8263) %>%
  #   # filter(x > -98.061 & x < -98.0605) %>%
  #   #filter(id == "13f92cd5-7e56-429c-9998-1b65403b6bb6" | id == "1225") %>% 
  #   #1225 is the big male tree in the open with intensive study 
  #   #"13f92cd5-7e56-429c-9998-1b65403b6bb6" is a female tree with a similar structure nearby
  #   
  #   #filter(ps_date > ymd("2020-12-01") & ps_date <  ymd("2021-05-01")) %>% 
  #   mutate(hz_index = red + blue * 0.7) %>% 
  #   ggplot(aes(x = ps_date, y = hz_index, color = sex, group = xy)) + geom_point(alpha = 0.2) + theme_bw() + 
  #   geom_line() 
  
  
#creating a ranking of trees 
#test <- 
  ps_p2021_wade %>% 
    group_by(ps_date) %>% 
    mutate(hz_index = red + blue * 0.7,
           hz_rank = rank(hz_index, ties.method = "first"),
           r2g_rank = rank(red / green , ties.method = "first"),
           yellow_rank = rank((red + green )/ blue, ties.method = "first")) %>% 
 # filter(id == "13f92cd5-7e56-429c-9998-1b65403b6bb6" | id == "1225")
  
filter(ps_date > ymd("2020-12-01") & ps_date <  ymd("2021-05-01")) %>% 

  ggplot(aes(x = ps_date, y = hz_rank, color = sex, group = xy)) + geom_point(alpha = 0.2) + theme_bw() + 
  #geom_line() +
  scale_color_manual(values = c("green", "orange"))
  
  
ps_p2021_wade %>% 
  group_by(ps_date) %>% 
  mutate(hz_index = red + blue * 0.7,
         hz_rank = rank(hz_index, ties.method = "first"),
         r2g_rank = rank(red / green , ties.method = "first"),
         yellow_rank = rank((red + green )/ blue, ties.method = "first")) %>% 
  # filter(id == "13f92cd5-7e56-429c-9998-1b65403b6bb6" | id == "1225")
  
#  filter(ps_date > ymd("2020-12-01") & ps_date <  ymd("2021-05-01")) %>% 
  group_by(ps_date, sex) %>% 
  summarize(mean_hz_rank = mean(hz_rank),
            mean_r2g_rank = mean(r2g_rank),
            mean_yellow_rank = mean(yellow_rank)) %>% 
  
  ggplot(aes(x = ps_date, y = mean_hz_rank, color = sex)) + geom_point(alpha = 0.2) + theme_bw() + 
  geom_line(aes(ps_date, y = zoo::rollmean(mean_hz_rank, 7, na.pad=TRUE)))+
  scale_color_manual(values = c("green", "orange"))

