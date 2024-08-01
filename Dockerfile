# IF YOU CHANGE ANYTHING HERE, UPDATE CI_IMAGE version in .gitlab.ci.yml
# docker login registry.git.rwth-aachen.de
# use arch because it provides a 2024 version of texlive without having to use the slow official download
FROM archlinux:base-devel

RUN echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN cat <<EOF >> /etc/pacman.conf
[core-debug]
Include = /etc/pacman.d/mirrorlist

[extra-debug]
Include = /etc/pacman.d/mirrorlist
EOF

RUN pacman -Syu --noconfirm && pacman -S --noconfirm texlive texlive-langgerman biber minted git jdk-openjdk jdk-openjdk-debug sbt npm chromium noto-fonts noto-fonts-emoji jq gnuplot && pacman -Scc --noconfirm

RUN echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers.d/wheel-nopasswd

RUN useradd -G wheel -ms /bin/bash arch
USER arch
WORKDIR /home/arch

RUN git clone https://aur.archlinux.org/async-profiler.git && cd async-profiler && git checkout 1959c80d19329a0d39ba7dc80805bf3197091a7f && makepkg -si --noconfirm && cd .. && rm -R async-profiler
RUN git clone https://aur.archlinux.org/verapdf.git && cd verapdf && git checkout 7ebd0835643aaf249b1b9b3b84ee44103a74a3ee && makepkg -si --noconfirm && cd .. && rm -R verapdf

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/async-profiler/lib/"
ENV PATH="${PATH}:/usr/bin/vendor_perl"

RUN cat <<EOF >> build.sbt
ThisBuild / scalaVersion := "3.4.2"

lazy val textrdt = project
  .in(file("."))
  .settings(
    name := "textrdt",
    libraryDependencies += "com.microsoft.playwright" % "playwright" % "1.44.0"
  )
EOF
RUN sbt "textrdt/runMain com.microsoft.playwright.CLI install"
RUN rm build.sbt